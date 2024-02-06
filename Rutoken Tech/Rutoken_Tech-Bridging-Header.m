//
//  Rutoken_Tech-Bridging-Header.m
//  Rutoken Tech
//
//  Created by Vova Badyaev on 18.01.2024.
//

#include "Rutoken_Tech-Bridging-Header.h"


void exposed_sk_X509_EXTENSION_pop_free(STACK_OF(X509_EXTENSION) *sk, void(*freefunc)(X509_EXTENSION*)) {
    sk_X509_EXTENSION_pop_free(sk, freefunc);
}

const EVP_MD * exposed_EVP_get_digestbynid(int type) {
    return EVP_get_digestbynid(type);
}

int exposed_sk_X509_EXTENSION_num(STACK_OF(X509_EXTENSION) *sk) {
    return sk_X509_EXTENSION_num(sk);
}

X509_EXTENSION * exposed_sk_X509_EXTENSION_value(STACK_OF(X509_EXTENSION) *sk, int idx) {
    return sk_X509_EXTENSION_value(sk, idx);
}

