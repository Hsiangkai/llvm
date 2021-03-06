; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -guard-widening-widen-frequent-branches=true -guard-widening-frequent-branch-threshold=1000 -S -guard-widening < %s        | FileCheck %s
; RUN: opt -guard-widening-widen-frequent-branches=true -guard-widening-frequent-branch-threshold=1000 -S -passes='require<branch-prob>,guard-widening' < %s | FileCheck %s

declare void @llvm.experimental.guard(i1,...)
declare void @foo()
declare void @bar()

; Check that we don't widen without branch probability.
define void @test_01(i1 %cond_0, i1 %cond_1) {
; CHECK-LABEL: @test_01(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[COND_0:%.*]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 [[COND_1:%.*]], label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]]
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE:%.*]]
; CHECK:       if.false:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %if.false

if.true:
  call void @foo()
  br label %merge

if.false:
  call void @bar()
  br label %merge

merge:
  ret void
}

; Check that we don't widen with branch probability below threshold.
define void @test_02(i1 %cond_0, i1 %cond_1) {
; CHECK-LABEL: @test_02(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[COND_0:%.*]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 [[COND_1:%.*]], label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]], !prof !0
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE:%.*]]
; CHECK:       if.false:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %if.false, !prof !0

if.true:
  call void @foo()
  br label %merge

if.false:
  call void @bar()
  br label %merge

merge:
  ret void
}

; Check that we widen conditions of explicit branches into dominating guards
; when the probability is high enough.
define void @test_03(i1 %cond_0, i1 %cond_1) {
; CHECK-LABEL: @test_03(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_1:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 true, label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]], !prof !1
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE:%.*]]
; CHECK:       if.false:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %if.false, !prof !1

if.true:
  call void @foo()
  br label %merge

if.false:
  call void @bar()
  br label %merge

merge:
  ret void
}

; Widen loop-invariant condition into the guard in preheader.
define void @test_04(i1 %cond_0, i1 %cond_1, i32 %n) {
; CHECK-LABEL: @test_04(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_1:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK]]) [ "deopt"() ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[MERGE:%.*]] ]
; CHECK-NEXT:    br i1 true, label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]], !prof !1
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       if.false:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[COND:%.*]] = icmp slt i32 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[COND]], label [[LOOP]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %merge ]
  br i1 %cond_1, label %if.true, label %if.false, !prof !1

if.true:
  call void @foo()
  br label %merge

if.false:
  call void @bar()
  br label %merge

merge:
  %iv.next = add i32 %iv, 1
  %cond = icmp slt i32 %iv.next, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

; Widen loop-invariant condition into the guard in the same loop.
define void @test_05(i1 %cond_0, i1 %cond_1, i32 %n) {
; CHECK-LABEL: @test_05(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[MERGE:%.*]] ]
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_1:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 true, label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]], !prof !1
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       if.false:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[COND:%.*]] = icmp slt i32 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[COND]], label [[LOOP]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %merge ]
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %if.false, !prof !1

if.true:
  call void @foo()
  br label %merge

if.false:
  call void @bar()
  br label %merge

merge:
  %iv.next = add i32 %iv, 1
  %cond = icmp slt i32 %iv.next, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

; Some of checks are frequently taken and some are not, make sure that we only
; widen frequent ones.
define void @test_06(i1 %cond_0, i1 %cond_1, i1 %cond_2, i1 %cond_3, i1 %cond_4, i32 %n) {
; CHECK-LABEL: @test_06(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_2:%.*]]
; CHECK-NEXT:    [[WIDE_CHK1:%.*]] = and i1 [[WIDE_CHK]], [[COND_4:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK1]]) [ "deopt"() ]
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[IV_NEXT:%.*]], [[BACKEDGE:%.*]] ]
; CHECK-NEXT:    br i1 [[COND_1:%.*]], label [[IF_TRUE_1:%.*]], label [[IF_FALSE_1:%.*]], !prof !2
; CHECK:       if.true_1:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE_1:%.*]]
; CHECK:       if.false_1:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE_1]]
; CHECK:       merge_1:
; CHECK-NEXT:    br i1 true, label [[IF_TRUE_2:%.*]], label [[IF_FALSE_2:%.*]], !prof !1
; CHECK:       if.true_2:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE_2:%.*]]
; CHECK:       if.false_2:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE_2]]
; CHECK:       merge_2:
; CHECK-NEXT:    br i1 [[COND_3:%.*]], label [[IF_TRUE_3:%.*]], label [[IF_FALSE_3:%.*]], !prof !2
; CHECK:       if.true_3:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE_3:%.*]]
; CHECK:       if.false_3:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[MERGE_3]]
; CHECK:       merge_3:
; CHECK-NEXT:    br i1 true, label [[IF_TRUE_4:%.*]], label [[IF_FALSE_4:%.*]], !prof !1
; CHECK:       if.true_4:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[BACKEDGE]]
; CHECK:       if.false_4:
; CHECK-NEXT:    call void @bar()
; CHECK-NEXT:    br label [[BACKEDGE]]
; CHECK:       backedge:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[COND:%.*]] = icmp slt i32 [[IV_NEXT]], [[N:%.*]]
; CHECK-NEXT:    br i1 [[COND]], label [[LOOP]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %backedge ]
  br i1 %cond_1, label %if.true_1, label %if.false_1, !prof !2

if.true_1:
  call void @foo()
  br label %merge_1

if.false_1:
  call void @bar()
  br label %merge_1

merge_1:
  br i1 %cond_2, label %if.true_2, label %if.false_2, !prof !1

if.true_2:
  call void @foo()
  br label %merge_2

if.false_2:
  call void @bar()
  br label %merge_2

merge_2:
  br i1 %cond_3, label %if.true_3, label %if.false_3, !prof !2

if.true_3:
  call void @foo()
  br label %merge_3

if.false_3:
  call void @bar()
  br label %merge_3

merge_3:
  br i1 %cond_4, label %if.true_4, label %if.false_4, !prof !1

if.true_4:
  call void @foo()
  br label %backedge

if.false_4:
  call void @bar()
  br label %backedge

backedge:
  %iv.next = add i32 %iv, 1
  %cond = icmp slt i32 %iv.next, %n
  br i1 %cond, label %loop, label %exit

exit:
  ret void
}

; Check triangle CFG pattern.
define void @test_07(i1 %cond_0, i1 %cond_1) {
; CHECK-LABEL: @test_07(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_1:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 true, label [[IF_TRUE:%.*]], label [[MERGE:%.*]], !prof !1
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE]]
; CHECK:       merge:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %merge, !prof !1

if.true:
  call void @foo()
  br label %merge

merge:
  ret void
}

define void @test_08(i1 %cond_0, i1 %cond_1) {
; CHECK-LABEL: @test_08(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[WIDE_CHK:%.*]] = and i1 [[COND_0:%.*]], [[COND_1:%.*]]
; CHECK-NEXT:    call void (i1, ...) @llvm.experimental.guard(i1 [[WIDE_CHK]]) [ "deopt"() ]
; CHECK-NEXT:    br i1 true, label [[IF_TRUE:%.*]], label [[IF_FALSE:%.*]], !prof !1
; CHECK:       if.true:
; CHECK-NEXT:    call void @foo()
; CHECK-NEXT:    br label [[MERGE:%.*]]
; CHECK:       if.false:
; CHECK-NEXT:    ret void
; CHECK:       merge:
; CHECK-NEXT:    ret void
;
entry:
  call void(i1, ...) @llvm.experimental.guard(i1 %cond_0) [ "deopt"() ]
  br i1 %cond_1, label %if.true, label %if.false, !prof !1

if.true:
  call void @foo()
  br label %merge

if.false:
  ret void

merge:
  ret void
}

!0 = !{!"branch_weights", i32 998, i32 1}
!1 = !{!"branch_weights", i32 999, i32 1}
!2 = !{!"branch_weights", i32 500, i32 500}
