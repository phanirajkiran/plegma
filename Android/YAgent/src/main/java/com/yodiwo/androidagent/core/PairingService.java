package com.yodiwo.androidagent.core;

import android.app.IntentService;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.webkit.CookieManager;
import android.webkit.CookieSyncManager;
import android.webkit.ValueCallback;

import com.yodiwo.androidagent.plegma.ApiRestAccess;
import com.yodiwo.androidagent.plegma.PairingNodeGetKeysRequest;
import com.yodiwo.androidagent.plegma.PairingNodeGetTokensRequest;
import com.yodiwo.androidagent.plegma.PairingServerKeysResponse;
import com.yodiwo.androidagent.plegma.PairingServerTokensResponse;

public class PairingService extends IntentService {

    // =============================================================================================
    // Static information's

    public static final String TAG = PairingService.class.getSimpleName();

    public static final String EXTRA_REQUEST_TYPE = "EXTRA_REQUEST_TYPE";
    public static final String EXTRA_STATUS = "EXTRA_STATUS";

    public static final String BROADCAST_PHASE1_FINISHED = "PairingService.BROADCAST_PHASE1_FINISHED";
    public static final String BROADCAST_PAIRING_FINISHED = "PairingService.BROADCAST_PAIRING_FINISHED";
    public static final String BROADCAST_MODAL_DIALOG_FINISHED = "PairingService.BROADCAST_MODAL_DIALOG_FINISHED";

    public static final int REQUEST_START_PAIRING = 0;
    public static final int REQUEST_FINISH_PAIRING = 1;

    public static final int EXTRA_STATUS_SUCCESS = 0;
    public static final int EXTRA_STATUS_FAILED = 1;

    private static PairingStatus pairingStatus;
    private static Boolean isReset = false;

    public enum PairingStatus{
        UNPAIRED,
        PHASE1ONGOING,
        PHASE1FINISHED,
        PAIRED
    }

    // =============================================================================================
    // Service overrides

    private ApiRestAccess apiRestAccess = null;
    private SettingsProvider settingsProvider;

    public PairingService() {
        super("PairingService");
    }

    public PairingService(String name) {
        super(name);
    }

    @Override
    protected void onHandleIntent(Intent intent) {

        Helpers.log(Log.DEBUG, TAG, "Handle message");
        settingsProvider = SettingsProvider.getInstance(getApplicationContext());


        if (apiRestAccess == null)
            apiRestAccess = new ApiRestAccess(getPairingWebUrl(settingsProvider));

        int request_type = intent.getExtras().getInt(EXTRA_REQUEST_TYPE);
        switch (request_type) {
            case REQUEST_START_PAIRING:
                pairingStatus = PairingStatus.PHASE1ONGOING;
                StartPairing(settingsProvider);
                break;
            case REQUEST_FINISH_PAIRING:
                FinishPairing(settingsProvider);
                break;
        }

    }

    // =============================================================================================
    // Service execution (background thread)

    private void StartPairing(SettingsProvider settingsProvider) {

        Helpers.log(Log.DEBUG, TAG, "Start Pairing");
        Intent intent = new Intent(BROADCAST_PHASE1_FINISHED);

        // Get Tokens from server
        try {
            PairingNodeGetTokensRequest req = new PairingNodeGetTokensRequest();
            req.uuid = settingsProvider.getNodeUUID();
            req.name = settingsProvider.getDeviceName();
            req.RedirectUri = PairingService.getPairingWebUrl(SettingsProvider.getInstance(this)) + "/pairing/1/success";
            req.NoUUIDAuthentication = true;

            PairingServerTokensResponse resp = apiRestAccess.service.SendPairingGetTokens(req);
            Helpers.log(Log.DEBUG, TAG, "Tokens: " + resp.token1 + ", " + resp.token2);

            // Save tokens
            settingsProvider.setNodeTokens(resp.token1, resp.token2);

            // Add extra status
            intent.putExtra(EXTRA_STATUS, EXTRA_STATUS_SUCCESS);
        } catch (Exception e) {
            Helpers.logException(TAG, e);

            // Add extra status for failed
            intent.putExtra(EXTRA_STATUS, EXTRA_STATUS_FAILED);
        }

        // Broadcast the finish of the first pairing
        LocalBroadcastManager
                .getInstance(getApplicationContext())
                .sendBroadcast(intent);
    }

    // ---------------------------------------------------------------------------------------------

    private void FinishPairing(SettingsProvider settingsProvider) {
        Intent intent = new Intent(BROADCAST_PAIRING_FINISHED);

        Helpers.log(Log.DEBUG, TAG, "Finish Pairing");

        // Get Tokens from server
        try {
            PairingNodeGetKeysRequest req = new PairingNodeGetKeysRequest();
            req.uuid = settingsProvider.getNodeUUID();
            req.token1 = settingsProvider.getNodeToken1();
            req.token2 = settingsProvider.getNodeToken2();

            PairingServerKeysResponse resp = apiRestAccess.service.SendPairingGetKeys(req);
            //Helpers.log(Log.DEBUG, TAG, "Keys: " + resp.nodeKey + ", " + resp.secretKey);

            // Save tokens
            settingsProvider.setNodeKeys(resp.nodeKey, resp.secretKey);

            // Add extra status
            intent.putExtra(EXTRA_STATUS, EXTRA_STATUS_SUCCESS);
        } catch (Exception e) {
            Helpers.logException(TAG, e);

            if (settingsProvider.getNodeKey() != null && settingsProvider.getNodeSecretKey() != null)
                intent.putExtra(EXTRA_STATUS, EXTRA_STATUS_SUCCESS);
            else
                intent.putExtra(EXTRA_STATUS, EXTRA_STATUS_FAILED);
        }

        // Broadcast the finish of the first pairing
        LocalBroadcastManager
                .getInstance(getApplicationContext())
                .sendBroadcast(intent);
    }

    // =============================================================================================
    // Public Functions

    public static void StartPairing(Context context) {
        Intent intent = new Intent(context, PairingService.class);
        intent.putExtra(EXTRA_REQUEST_TYPE, REQUEST_START_PAIRING);
        context.startService(intent);
    }

    // ---------------------------------------------------------------------------------------------

    public static String getPairingUserCfmUrl(Context context) {
        SettingsProvider settingsProvider = SettingsProvider.getInstance(context);
        String path = getPairingWebUrl(settingsProvider);

        return path
                + "/pairing/1/userconfirm"
                + "?token2=" + settingsProvider.getNodeToken2()
                + "&uuid=" + settingsProvider.getNodeUUID();
    }

    public static String getPairingWebUrl(SettingsProvider settingsProvider) {
        boolean useSSL = settingsProvider.getServerUseSSL();
        return (useSSL ? "https://" : "http://") +
                settingsProvider.getServerAddress() + ":" +
                Integer.toString(useSSL ? 443 : 3334);
    }

    // ---------------------------------------------------------------------------------------------

    public static void FinishPairing(Context context) {
        Intent intent = new Intent(context, PairingService.class);
        intent.putExtra(EXTRA_REQUEST_TYPE, REQUEST_FINISH_PAIRING);
        context.startService(intent);
    }

    // ---------------------------------------------------------------------------------------------

    public static PairingStatus getPairingStatus(){
        return pairingStatus;
    }

    // ---------------------------------------------------------------------------------------------

    public static void setPairingStatus(PairingStatus status) {
        pairingStatus = status;
    }

    // ---------------------------------------------------------------------------------------------

    public static Boolean getResetStatus(){
        return isReset;
    }

    // ---------------------------------------------------------------------------------------------

    public static void setResetStatus(Boolean status) {
        isReset = status;
    }

    // ---------------------------------------------------------------------------------------------

    public static void UnPair(Context context, boolean isUnpairedByUser) {
        SettingsProvider settingsProvider = SettingsProvider.getInstance(context);
        settingsProvider.setNodeKeys(null, null);
        settingsProvider.setNodeTokens(null, null);

        // reset mqtt connection
        NodeService.Reset(context);

        pairingStatus = PairingStatus.UNPAIRED;

        // Remove cookies
        CookieManager cookieManager = CookieManager.getInstance();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.removeAllCookies(new ValueCallback<Boolean>() {
                @Override
                public void onReceiveValue(Boolean aBoolean) {}
            });
        }
        else {
            CookieSyncManager.createInstance(context);
            cookieManager.removeAllCookie();
        }

        // inform modalDialog
        ModalDialogActivity.isShown = false;

        // Broadcast unpairing info
        Intent intent = new Intent(NodeService.BROADCAST_NODE_UNPAIRING);
        intent.putExtra(NodeService.EXTRA_NODE_UNPAIRING_INFO, isUnpairedByUser);

        LocalBroadcastManager
                .getInstance(context)
                .sendBroadcast(intent);
    }

    // ---------------------------------------------------------------------------------------------

    // =============================================================================================
}
