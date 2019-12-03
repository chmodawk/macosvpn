import Darwin
import SystemConfiguration

open class VPNServiceConfig {
  public enum Kind: String {
    case L2TPOverIPSec
    case CiscoIPSec
    case Unknown
  }

  public init(kind: Kind, name: String, endpoint: String) {
    self.kind = kind
    self.name = name
    self.endpoint = endpoint
  }

  public var kind: Kind

  // Assigned on-the-fly once generated by the OS
  public var serviceID: String?
  
  // Both L2TP and Cisco
  public var name: String
  public var endpoint: String
  
  public var username: String?
  public var password: String?
  public var sharedSecret: String?
  public var localIdentifier: String?
  
  // L2TP-specific
  public var enableSplitTunnel: Bool = false
  public var disconnectOnSwitch: Bool = false
  public var disconnectOnLogout: Bool = false
  
  public var humanKind: String {
    switch kind {
    case .L2TPOverIPSec: return "L2TP"
    case .CiscoIPSec: return "Cisco"
    default:
      return "Unknown"
    }
  }

  public var description: String {
    "<[VPNServiceConfig] name=\(name) endpoint=\(endpoint) username=\(String(describing: username)) password=\(String(describing: password)) sharedSecret=\(String(describing: sharedSecret)) localIdentifier=\(String(describing: localIdentifier))>"
  }
  
  public var l2TPPPPConfig: CFDictionary {
    Log.debug("Assembling l2TPPPPConfig configuration dictionary...")
    var result: [CFString: CFString?] = [:]

    result.updateValue(endpoint as CFString?,
                       forKey: kSCPropNetPPPCommRemoteAddress)

    result.updateValue(username as CFString?,
                       forKey: kSCPropNetPPPAuthName)

    result.updateValue(serviceID as CFString?,
                       forKey: kSCPropNetPPPAuthPassword)

    result.updateValue(kSCValNetPPPAuthPasswordEncryptionKeychain,
                       forKey: kSCPropNetPPPAuthPasswordEncryption)

    // CFNumber is the correct type I think, as you can verify in the resulting /Library/Preferences/SystemConfiguration/preferences.plist file.
    // However, the documentation says CFString, so I'm not sure whom to believe.
    // See https://developer.apple.com/documentation/systemconfiguration/kscpropnetpppdisconnectonfastuserswitch
    // See also https://developer.apple.com/library/prerelease/ios/documentation/CoreFoundation/Conceptual/CFPropertyLists/Articles/Numbers.html
    let switchOne = disconnectOnSwitch ? "1" : "0"

    result.updateValue(switchOne as CFString?,
                       forKey: kSCPropNetPPPDisconnectOnFastUserSwitch)

    // Again, not sure if CFString or CFNumber is more valid
    let logoutOne = disconnectOnLogout ? "1" : "0"

    result.updateValue(logoutOne as CFString?,
                       forKey: kSCPropNetPPPDisconnectOnLogout)
    Log.debug("l2TPIPSecConfig ready: \(result)")

    return result as CFDictionary

  }
  
  public var l2TPIPSecConfig: CFDictionary {
    Log.debug("Assembling l2TPIPSecConfig configuration dictionary...")
    var result: [CFString: CFString?] = [:]

    result.updateValue(kSCValNetIPSecAuthenticationMethodSharedSecret,
                       forKey: kSCPropNetIPSecAuthenticationMethod)

    result.updateValue(kSCValNetIPSecSharedSecretEncryptionKeychain,
                       forKey: kSCPropNetIPSecSharedSecretEncryption)

    guard let unwrappedServiceID = serviceID else {
      Log.error("Could not unwrap the ServiceID")
      exit(999)
    }

    result.updateValue("\(unwrappedServiceID).SS" as CFString,
                       forKey: kSCPropNetIPSecSharedSecret)

    if (localIdentifier) != nil {
      Log.debug("Assigning group name \(String(describing: localIdentifier)) to L2TP service config")

      result.updateValue(localIdentifier as CFString?,
                         forKey: kSCPropNetIPSecLocalIdentifier)

      result.updateValue(kSCValNetIPSecLocalIdentifierTypeKeyID,
                         forKey: kSCPropNetIPSecLocalIdentifierType)

    }

    Log.debug("l2TPIPSecConfig ready: \(result)")

    return result as CFDictionary
  }

  public var l2TPIPv4Config: CFDictionary {
    Log.debug("Assembling l2TPIPv4Config configuration dictionary...")
    var result: [CFString: CFString?] = [:]

    result.updateValue(kSCValNetIPv4ConfigMethodPPP,
                       forKey: kSCPropNetIPv4ConfigMethod)

    if !enableSplitTunnel {
      result.updateValue("1" as CFString?,
                         forKey: kSCPropNetOverridePrimary)
    }

    Log.debug("l2TPIPv4Config ready: \(result)")

    return result as CFDictionary
  }

  public var ciscoConfig: CFDictionary {
    Log.debug("Assembling ciscoConfig configuration dictionary...")
    var result: [CFString: CFString?] = [:]

    result.updateValue(kSCValNetIPSecAuthenticationMethodSharedSecret,
                       forKey: kSCPropNetIPSecAuthenticationMethod)

    guard let unwrappedServiceID = serviceID else {
      Log.error("Could not unwrap the ServiceID")
      exit(999)
    }
    
    result.updateValue("\(unwrappedServiceID).SS" as CFString,
                       forKey: kSCPropNetIPSecSharedSecret)

    result.updateValue(kSCValNetIPSecSharedSecretEncryptionKeychain,
                       forKey: kSCPropNetIPSecSharedSecretEncryption)

    result.updateValue(endpoint as CFString?,
                       forKey: kSCPropNetIPSecRemoteAddress)

    result.updateValue(username as CFString?,
                       forKey: kSCPropNetIPSecXAuthName)

    result.updateValue(serviceID as CFString?,
                       forKey: kSCPropNetIPSecXAuthPassword)

    result.updateValue(kSCValNetIPSecXAuthPasswordEncryptionKeychain,
                       forKey: kSCPropNetIPSecXAuthPasswordEncryption)

    if (localIdentifier) != nil {
      Log.debug("Assigning group name \(String(describing: localIdentifier)) to Cisco service config")

      result.updateValue(localIdentifier as CFString?,
                         forKey: kSCPropNetIPSecLocalIdentifier)

      result.updateValue(kSCValNetIPSecLocalIdentifierTypeKeyID,
                         forKey: kSCPropNetIPSecLocalIdentifierType)
    }

    Log.debug("ciscoConfig ready: \(result)")

    return result as CFDictionary
  }
}

