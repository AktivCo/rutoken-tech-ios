//
//  Rutoken_Tech-Bridging-Header.h
//  Rutoken Tech
//
//  Created by Vova Badyaev on 24.11.2023.
//

#ifndef Rutoken_Tech_Bridging_Header_h
#define Rutoken_Tech_Bridging_Header_h

#include <rtpkcs11ecp/rtpkcs11.h>
#include <rtpkcs11ecp/cryptoki.h>

#include <openssl/configuration.h>
#undef OPENSSL_NO_DEPRECATED
#define OPENSSL_SUPPRESS_DEPRECATED

#include <rtengine/engine.h>

#endif /* Rutoken_Tech_Bridging_Header_h */
