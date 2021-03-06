; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown                        | FileCheck %s --check-prefixes=ANY,STRICT
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -enable-unsafe-fp-math | FileCheck %s --check-prefixes=ANY,UNSAFE

define float @fadd_zero(float %x) {
; STRICT-LABEL: fadd_zero:
; STRICT:       # %bb.0:
; STRICT-NEXT:    xorps %xmm1, %xmm1
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fadd_zero:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    retq
  %r = fadd float %x, 0.0
  ret float %r
}

define float @fadd_negzero(float %x) {
; ANY-LABEL: fadd_negzero:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fadd float %x, -0.0
  ret float %r
}

define float @fadd_produce_zero(float %x) {
; ANY-LABEL: fadd_produce_zero:
; ANY:       # %bb.0:
; ANY-NEXT:    xorps %xmm0, %xmm0
; ANY-NEXT:    retq
  %neg = fsub nsz float 0.0, %x
  %r = fadd nnan float %neg, %x
  ret float %r
}

define float @fadd_reassociate(float %x) {
; ANY-LABEL: fadd_reassociate:
; ANY:       # %bb.0:
; ANY-NEXT:    addss {{.*}}(%rip), %xmm0
; ANY-NEXT:    retq
  %sum = fadd float %x, 8.0
  %r = fadd reassoc nsz float %sum, 12.0
  ret float %r
}

define float @fadd_negzero_nsz(float %x) {
; ANY-LABEL: fadd_negzero_nsz:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fadd nsz float %x, -0.0
  ret float %r
}

define float @fadd_zero_nsz(float %x) {
; ANY-LABEL: fadd_zero_nsz:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fadd nsz float %x, 0.0
  ret float %r
}

define float @fsub_zero(float %x) {
; ANY-LABEL: fsub_zero:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fsub float %x, 0.0
  ret float %r
}

define float @fsub_self(float %x) {
; ANY-LABEL: fsub_self:
; ANY:       # %bb.0:
; ANY-NEXT:    xorps %xmm0, %xmm0
; ANY-NEXT:    retq
  %r = fsub nnan float %x, %x
  ret float %r
}

define float @fsub_neg_x_y(float %x, float %y) {
; ANY-LABEL: fsub_neg_x_y:
; ANY:       # %bb.0:
; ANY-NEXT:    subss %xmm0, %xmm1
; ANY-NEXT:    movaps %xmm1, %xmm0
; ANY-NEXT:    retq
  %neg = fsub nsz float 0.0, %x
  %r = fadd nsz float %neg, %y
  ret float %r
}

define float @fsub_neg_y(float %x, float %y) {
; STRICT-LABEL: fsub_neg_y:
; STRICT:       # %bb.0:
; STRICT-NEXT:    mulss {{.*}}(%rip), %xmm0
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    subss %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_neg_y:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    mulss {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    subss %xmm1, %xmm0
; UNSAFE-NEXT:    addss %xmm1, %xmm0
; UNSAFE-NEXT:    retq
  %mul = fmul float %x, 5.0
  %add = fadd float %mul, %y
  %r = fsub nsz reassoc float %y, %add
  ret float %r
}

define float @fsub_neg_y_commute(float %x, float %y) {
; STRICT-LABEL: fsub_neg_y_commute:
; STRICT:       # %bb.0:
; STRICT-NEXT:    mulss {{.*}}(%rip), %xmm0
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    subss %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_neg_y_commute:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    mulss {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    subss %xmm1, %xmm0
; UNSAFE-NEXT:    addss %xmm1, %xmm0
; UNSAFE-NEXT:    retq
  %mul = fmul float %x, 5.0
  %add = fadd float %y, %mul
  %r = fsub nsz reassoc float %y, %add
  ret float %r
}
; Y - (X + Y) --> -X

define float @fsub_fadd_common_op_fneg(float %x, float %y) {
; STRICT-LABEL: fsub_fadd_common_op_fneg:
; STRICT:       # %bb.0:
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    subss %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_fadd_common_op_fneg:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    xorps {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    retq
  %a = fadd float %x, %y
  %r = fsub reassoc nsz float %y, %a
  ret float %r
}

; Y - (X + Y) --> -X

define <4 x float> @fsub_fadd_common_op_fneg_vec(<4 x float> %x, <4 x float> %y) {
; STRICT-LABEL: fsub_fadd_common_op_fneg_vec:
; STRICT:       # %bb.0:
; STRICT-NEXT:    addps %xmm1, %xmm0
; STRICT-NEXT:    subps %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_fadd_common_op_fneg_vec:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    xorps {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    retq
  %a = fadd <4 x float> %x, %y
  %r = fsub nsz reassoc <4 x float> %y, %a
  ret <4 x float> %r
}

; Y - (Y + X) --> -X
; Commute operands of the 'add'.

define float @fsub_fadd_common_op_fneg_commute(float %x, float %y) {
; STRICT-LABEL: fsub_fadd_common_op_fneg_commute:
; STRICT:       # %bb.0:
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    subss %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_fadd_common_op_fneg_commute:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    xorps {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    retq
  %a = fadd float %y, %x
  %r = fsub reassoc nsz float %y, %a
  ret float %r
}

; Y - (Y + X) --> -X

define <4 x float> @fsub_fadd_common_op_fneg_commute_vec(<4 x float> %x, <4 x float> %y) {
; STRICT-LABEL: fsub_fadd_common_op_fneg_commute_vec:
; STRICT:       # %bb.0:
; STRICT-NEXT:    addps %xmm1, %xmm0
; STRICT-NEXT:    subps %xmm0, %xmm1
; STRICT-NEXT:    movaps %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_fadd_common_op_fneg_commute_vec:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    xorps {{.*}}(%rip), %xmm0
; UNSAFE-NEXT:    retq
  %a = fadd <4 x float> %y, %x
  %r = fsub reassoc nsz <4 x float> %y, %a
  ret <4 x float> %r
}

define float @fsub_negzero(float %x) {
; STRICT-LABEL: fsub_negzero:
; STRICT:       # %bb.0:
; STRICT-NEXT:    xorps %xmm1, %xmm1
; STRICT-NEXT:    addss %xmm1, %xmm0
; STRICT-NEXT:    retq
;
; UNSAFE-LABEL: fsub_negzero:
; UNSAFE:       # %bb.0:
; UNSAFE-NEXT:    retq
  %r = fsub float %x, -0.0
  ret float %r
}

define float @fsub_zero_nsz_1(float %x) {
; ANY-LABEL: fsub_zero_nsz_1:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fsub nsz float %x, 0.0
  ret float %r
}

define float @fsub_zero_nsz_2(float %x) {
; ANY-LABEL: fsub_zero_nsz_2:
; ANY:       # %bb.0:
; ANY-NEXT:    xorps {{.*}}(%rip), %xmm0
; ANY-NEXT:    retq
  %r = fsub nsz float 0.0, %x
  ret float %r
}

define float @fsub_negzero_nsz(float %x) {
; ANY-LABEL: fsub_negzero_nsz:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fsub nsz float %x, -0.0
  ret float %r
}

define float @fmul_zero(float %x) {
; ANY-LABEL: fmul_zero:
; ANY:       # %bb.0:
; ANY-NEXT:    xorps %xmm0, %xmm0
; ANY-NEXT:    retq
  %r = fmul nnan nsz float %x, 0.0
  ret float %r
}

define float @fmul_one(float %x) {
; ANY-LABEL: fmul_one:
; ANY:       # %bb.0:
; ANY-NEXT:    retq
  %r = fmul float %x, 1.0
  ret float %r
}

define float @fmul_x_const_const(float %x) {
; ANY-LABEL: fmul_x_const_const:
; ANY:       # %bb.0:
; ANY-NEXT:    mulss {{.*}}(%rip), %xmm0
; ANY-NEXT:    retq
  %mul = fmul reassoc float %x, 9.0
  %r = fmul reassoc float %mul, 4.0
  ret float %r
}
