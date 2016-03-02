﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Yodiwo.API.Plegma;
using Yodiwo.API.Plegma.NodePairing;
using Yodiwo.Node.Pairing;
using System.Net;
using System.ComponentModel;
using Yodiwo.NodeLibrary;

namespace Yodiwo.Node.Pairing
{
    public class NodePairingBackend
    {
        #region Variables
        //--------------------------------------------------------------------------------------------------------------------
        public string postUrl;
        private NodeConfig conf;
        string token1;
        string token2;
        public NodeKey? nodeKey;
        public string secretKey;
        //--------------------------------------------------------------------------------------------------------------------
        public delegate void OnPairedDelegate(NodeKey nodeKey, string nodeSecret);
        public event OnPairedDelegate onPaired = delegate { };
        //--------------------------------------------------------------------------------------------------------------------
        public delegate void OnPairingFailedDelegate(string Message);
        public event OnPairingFailedDelegate onPairingFailed = delegate { };
        //--------------------------------------------------------------------------------------------------------------------
        public string userUrl { get { return postUrl + "/" + NodePairingConstants.UserConfirmPageURI; } }
        //--------------------------------------------------------------------------------------------------------------------
        PairingStates pairingState;
        //--------------------------------------------------------------------------------------------------------------------
        #endregion

        #region Constructor
        //--------------------------------------------------------------------------------------------------------------------
        public NodePairingBackend(string postUrl, NodeConfig conf, OnPairedDelegate callback, OnPairingFailedDelegate onPairingFailedCB)
        {
            this.postUrl = postUrl + "/" + PlegmaAPI.APIVersion;
            this.conf = conf;
            pairingState = PairingStates.Initial;
            this.onPaired += callback;
            this.onPairingFailed += onPairingFailedCB;
        }
        //--------------------------------------------------------------------------------------------------------------------
        #endregion

        #region Functions
        //--------------------------------------------------------------------------------------------------------------------
        public string pairGetTokens(string redirectUri)
        {
            var req = new PairingNodeGetTokensRequest()
            {
                uuid = this.conf.uuid,
                name = this.conf.Name,
                image = this.conf.Image,
                description = this.conf.Description,
                pathcss = this.conf.Pathcss,
                RedirectUri = redirectUri,
            };
            var uri = this.postUrl + "/" + NodePairingConstants.s_GetTokensRequest;
            PairingServerTokensResponse resp = (PairingServerTokensResponse)jsonPost(uri, req, typeof(PairingServerTokensResponse));
            if (resp != null)
            {
                this.token1 = resp.token1;
                this.token2 = resp.token2;
                if (this.token1 != null && this.token2 != null)
                {
                    pairingState = PairingStates.TokensSentToNode;
                    return this.token2;
                }
            }
            return null;
        }
        //--------------------------------------------------------------------------------------------------------------------
        public Tuple<NodeKey, string> pairGetKeys()
        {
            if (pairingState != PairingStates.TokensSentToNode)
            {
                return null;
            }
            var req = new PairingNodeGetKeysRequest(this.token1, this.token2);
            var resp = (PairingServerKeysResponse)jsonPost(this.postUrl + "/" + NodePairingConstants.s_GetKeysRequest, req, typeof(PairingServerKeysResponse));
            if (resp != null)
            {
                this.nodeKey = resp.nodeKey;
                this.secretKey = resp.secretKey;
                if (this.nodeKey != null && !string.IsNullOrWhiteSpace(this.secretKey))
                {
                    onPaired(this.nodeKey.Value, this.secretKey);
                    return new Tuple<NodeKey, string>(this.nodeKey.Value, this.secretKey);
                }
                else
                    onPairingFailed("NodeKey or SecretKey are invalid");
            }
            else
                onPairingFailed("Could not get keys");
            return null;
        }
        //--------------------------------------------------------------------------------------------------------------------
        public static object jsonPost(string url, object data, Type responseType)
        {
            var response = default(Tools.Http.RequestResult);
            try
            {
                response = Yodiwo.Tools.Http.RequestPost(url, data.ToJSON(), HttpRequestDataFormat.Json, null);
                if (response.StatusCode == HttpStatusCode.OK && !string.IsNullOrWhiteSpace(response.ResponseBodyText))
                {
                    return response.ResponseBodyText.FromJSON(responseType);
                }
                else
                {
                    DebugEx.TraceWarning("post response: " + response.StatusCode.ToString());
                    return null;
                }
            }
            catch (Exception ex)
            {
                if (response.ResponseBodyText == null)
                    DebugEx.Assert(ex, "Pairing jsonPost failed (no body)");
                else
                    DebugEx.Assert(ex, "Pairing jsonPost failed" + Environment.NewLine + "Json Body : " + response.ResponseBodyText);
                return null;
            }
        }
        //--------------------------------------------------------------------------------------------------------------------
        #endregion
    }
}
