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
#include <openssl/cms.h>
#include <openssl/evp.h>

#include <rtengine/engine.h>

const EVP_MD * exposed_EVP_get_digestbynid(int type);

const EVP_CIPHER * exposed_EVP_get_cipherbynid(int type);

STACK_OF(X509)* exposed_sk_X509_new_null(void);

int exposed_sk_X509_push(STACK_OF(X509)* certStack, X509* cert);

void exposed_sk_X509_pop_free(STACK_OF(X509)* certStack);

STACK_OF(X509_EXTENSION)* exposed_sk_X509_EXTENSION_new_null(void);

int exposed_sk_X509_EXTENSION_num(STACK_OF(X509_EXTENSION) *sk);

X509_EXTENSION * exposed_sk_X509_EXTENSION_value(STACK_OF(X509_EXTENSION) *sk, int idx);

void exposed_sk_X509_EXTENSION_pop_free(STACK_OF(X509_EXTENSION) *sk, void(*freefunc)(X509_EXTENSION*));

STACK_OF(POLICYINFO)* create_stack_of_policyinfo(POLICYINFO** array, int count);

void exposed_sk_POLICYINFO_free(STACK_OF(POLICYINFO)* sk);

#endif /* Rutoken_Tech_Bridging_Header_h */
