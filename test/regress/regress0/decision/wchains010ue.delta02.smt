; COMMAND-LINE: --decision=justification
; EXPECT: unsat

(benchmark wchains010ue.smt
:logic QF_AUFBV
:extrafuns ((v6 BitVec[32]))
:extrafuns ((v7 BitVec[32]))
:extrafuns ((a1 Array[32:8]))
:status unsat
:formula
(let (?n1 bv0[1])
(let (?n2 bv0[2])
(let (?n3 (extract[1:0] v6))
(flet ($n4 (= ?n2 ?n3))
(let (?n5 bv1[1])
(let (?n6 (ite $n4 ?n5 ?n1))
(let (?n7 (extract[23:16] v6))
(let (?n8 (store a1 v6 ?n7))
(let (?n9 bv0[32])
(let (?n10 bv0[8])
(let (?n11 (store ?n8 ?n9 ?n10))
(let (?n12 (extract[23:16] v7))
(let (?n13 (store ?n11 v7 ?n12))
(let (?n14 bv1[32])
(let (?n15 (store ?n13 ?n14 ?n10))
(let (?n16 (store ?n15 ?n9 ?n10))
(let (?n17 (store a1 ?n9 ?n10))
(let (?n18 (store ?n17 v7 ?n12))
(let (?n19 (store ?n18 ?n14 ?n10))
(let (?n20 (store ?n19 v6 ?n7))
(flet ($n21 (= ?n16 ?n20))
(let (?n22 (ite $n21 ?n5 ?n1))
(let (?n23 (bvnot ?n22))
(let (?n24 (bvand ?n6 ?n23))
(flet ($n25 (= ?n1 ?n24))
(flet ($n26 (not $n25))
$n26
)))))))))))))))))))))))))))
