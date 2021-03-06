; COMMAND-LINE: --bool-to-bv
; EXPECT: sat
(set-logic QF_BV)
(declare-fun x2 () (_ BitVec 3))
(declare-fun x1 () (_ BitVec 3))
(declare-fun x0 () (_ BitVec 3))
(declare-fun b1 () Bool)
(declare-fun b2 () Bool)
(declare-fun b3 () Bool)
(assert (not (bvult (bvudiv (bvudiv (bvudiv x0 x0) x1) x2) x1)))
(assert (not (bvslt (bvudiv (bvudiv (bvudiv x0 x0) x1) x2) x1)))
(assert (= #b000 x2))
(assert (=> b1 b2))
(assert (and b1 b2))
(assert (or b1 b2))
(assert (xor b1 b3))
(assert (not (xor b2 b2)))
(assert (ite b2 b2 b1))
(check-sat)
