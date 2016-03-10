﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Yodiwo.PaaS.IBMProxyNode
{

    public class IBMInfo
    {
        public string IOTFDeviceName { get; set; }
        public string IOTFDeviceType { get; set; }
        public string IOTFOrganization { get; set; }
        public string IOTFAppName { get; set; }
        public string IOTFauthtoken { get; set; }
        public string IOTFApikey { get; set; }
    }

    public class YodiwoInfo
    {
        public string YodiwoNodeKey { get; set; }
        public string YodiwoSecretKey { get; set; }
        public string YodiwoRestUrl { get; set; }
        public string YodiwoApiServer { get; set; }
        public string YPChannelPort { get; set; }
        public bool SecureYPC { get; set; }
    }

    public class ThingDescriptor
    {
        public string Name { get; set; }
        public string Type { get; set; }
        public string IO { get; set; }
        public string FriendlyIcon { get; set; }
    }

    public class ThingsDescription
    {
        public List<ThingDescriptor> ThingDescriptor { get; set; }
    }

    public class NodeDescriptor
    {
        public IBMInfo IBMInfo { get; set; }
        public YodiwoInfo YodiwoInfo { get; set; }
        public ThingsDescription ThingsDescription { get; set; }
    }


}

