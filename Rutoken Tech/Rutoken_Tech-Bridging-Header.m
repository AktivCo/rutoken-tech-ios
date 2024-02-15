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

STACK_OF(POLICYINFO)* create_stack_of_policyinfo(POLICYINFO** array, int count) {
    STACK_OF(POLICYINFO)* stack = sk_POLICYINFO_new_null();
    if (stack == NULL) {
        return NULL;
    }
    for (int i = 0; i < count; i++) {
        if (!sk_POLICYINFO_push(stack, (POLICYINFO*)array[i])) {
            sk_POLICYINFO_free(stack);
            return NULL;
        }
    }
    return stack;
}

void exposed_sk_POLICYINFO_free(STACK_OF(POLICYINFO)* sk) {
    sk_POLICYINFO_free(sk);
}
