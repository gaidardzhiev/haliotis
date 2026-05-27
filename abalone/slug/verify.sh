#!/bin/sh
#Copyright (C) 2025 Ivan Gaydardzhiev
#Licensed under the GPL-3.0-only

G='\033[0;32m'
R='\033[0;31m'
N='\033[0m'

[ ! -f slug ] && make

fprint() {
	 printf "[%s] Test: %-20s Result: %b\n" "$(date '+%Y-%m-%d %H:%M:%S')" "${1}" "${2}"
}

test_ackermann() {
	capture=$(./slug scripts/ackermann.slg)
	[ "${capture}" = "1021" ] && {
		fprint "Ackermann(3,7)" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Ackermann(3,7)" "${R}FAILED${N}";
		return 2;
	}
}

test_increment() {
	capture=$(./slug scripts/anon_func.slg)
	[ "${capture}" = "8" ] && {
		fprint "Increment" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Increment" "${R}FAILED${N}";
		return 3;
	}
}

test_core_lang() {
	expected="20\n1\n0\n1\n2\n3\n4\n20\n15\n42"
	expected=$(printf '%b' "${expected}")
	capture=$(./slug scripts/core_language_test.slg)
	[ "${capture}" = "${expected}" ] && {
		fprint "Core Language" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Core Language" "${R}FAILED${N}";
		return 4;
	}
}

test_turing() {
	capture=$(./slug scripts/turing.slg)
	[ "${capture}" = "120" ] && {
		fprint "Turing Completeness" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Turing Completeness" "${R}FAILED${N}";
		return 5;
	}
}

test_hof() {
	capture=$(./slug scripts/higher_order_functions_and_closures.slg)
	[ "${capture}" = "25" ] && {
		fprint "Higher Order" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Higher Order" "${R}FAILED${N}";
		return 6;
	}
}

test_recursion() {
	capture=$(./slug scripts/recursion.slg)
	[ "${capture}" = "120" ] && {
		fprint "Recursion" "${G}PASSED${N}";
		return 0;
	} || { 
		fprint "Recursion" "${R}FAILED${N}";
		return 7;
	}
}

test_demorgan() {
	expected="true\ntrue\ntrue\ntrue\n"
	expected=$(printf %b "${expected}")
	capture=$(./slug scripts/demorgan_law.slg)
	[ "${capture}" = "${expected}" ] && {
		fprint "DeMorgan" "${G}PASSED${N}";
		return 0;
	} || { 
		fprint "DeMorgan" "${R}FAILED${N}";
		return 8;
	}
}

test_truth() {
	expected="true\ntrue\ntrue\ntrue\n"
	expected=$(printf %b "${expected}")
	capture=$(./slug scripts/truth_table_testing.slg)
	[ "${capture}" = "${expected}" ] && {
		fprint "Truth Table" "${G}PASSED${N}";
		return 0;
	} || {
		fprint "Truth Table" "${R}FAILED${N}";
		return 9;
	}
}

test_entscheidungs() {
	capture=$(./slug scripts/entscheidungs_problem.slg)
	[ "${capture}" = "0" ] && {
		fprint "EntscheidungsProblem" "${G}CONFIRMED${N}";
		return 0;
	} || {
		fprint "EntscheidungsProblem" "${R}REFUTED${N}";
		return 10;
	}
}

test_halting() {
	capture=$(./slug scripts/halting_paradox.slg)
	[ "${capture}" = "0" ] && {
		fprint "Halting Paradox" "${G}CONFIRMED${N}";
		return 0;
	} || {
		fprint "Halting Paradox" "${R}REFUTED${N}";
		return 	11;
	}
}

test_purediag() {
	exec 3>&2 2>/dev/null
	./slug scripts/pure_diag.slg
	capture="${?}"
	exec 2>&3 3>&-
	[ "${capture}" = "139" ] && {
		fprint "Self Reference" "${G}CONFIRMED${N}";
		return 0;
	} || {
		fprint "Self Reference" "${R}REFUTED${N}";
		return 	12;
	}
}

#TODO: add verification functions for church_numerals.slg & collatz.slg & palindrome_checker.slg & godel.slg

{ test_ackermann && test_increment && test_core_lang && test_turing && test_hof && test_recursion && test_demorgan && test_truth && test_entscheidungs && test_halting && test_purediag; ret="${?}"; } || exit 1

[ "${ret}" -eq 0 ] 2>/dev/null || printf "%s\n" "${ret}"
