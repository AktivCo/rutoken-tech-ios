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

#include <openssl/x509v3.h>
#include <openssl/evp.h>

#include <rtengine/engine.h>

void exposed_sk_X509_EXTENSION_pop_free(STACK_OF(X509_EXTENSION) *sk, void(*freefunc)(X509_EXTENSION*));

const EVP_MD * exposed_EVP_get_digestbynid(int type);

#endif /* Rutoken_Tech_Bridging_Header_h */
