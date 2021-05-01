;;; Unit tests for polymorph.copy-cast

(defpackage #:polymorph.copy-cast/test
  (:use #:cl
	#:fiveam
	#:polymorph.copy-cast)

  (:import-from #:alexandria
		#:alist-hash-table
		#:hash-table-alist
		#:set-equal)

  (:export #:polymorph.copy-cast
           #:test-polymorph.copy-cast))

(in-package #:polymorph.copy-cast/test)

;;; Test suite definition

(def-suite polymorph.copy-cast
    :description "Master test suite for polymorph.copy-cast")

(in-suite polymorph.copy-cast)

(defun test-polymorph.copy-cast ()
  (run! 'polymorph.copy-cast))


;;; CAST tests

(test cast-number
  "Test casting a number to other numeric types."

  (is (= 0.5 (cast 1/2 'float)))
  (is (= 1.5 (cast 3/2 'real)))

  (is (= (cast 3/2 'integer) 1))
  (is (= (cast 10.12 'integer) 10)))

(test cast-list
  "Test casting a list to boolean."

  (is (eq t (cast '(1 2 3 4) 'boolean)))
  (is (eq nil (cast nil 'boolean))))

(test cast-integer->character
  "Test casting an integer to a character."

  (is-every char=
    (#\0 (cast #x30 'character))
    (#\5 (cast #x35 'character))
    ((code-char 123456) (cast 123456 'character))))

(test cast-character->integer
  "Test casting a character to an integer."

  (is-every =
    (#x30 (cast #\0 'integer))
    (#x37 (cast #\7 'integer))
    (123456 (cast (code-char 123456) 'integer))))

(test cast-bit->boolean
  "Test casting a bit to a boolean."

  (is-every eq
    (t (cast 1 'boolean))
    (nil (cast 0 'boolean)))

  (signals adhoc-polymorphic-functions::no-applicable-polymorph
    (cast 2 'boolean)))

(test cast-boolean->bit
  "Test casting a boolean to a bit."

  (is-every =
    (1 (cast t 'bit))
    (0 (cast nil 'bit)))

  (signals adhoc-polymorphic-functions::no-applicable-polymorph
    (cast '(1 2 3) 'bit)))


;;; Copying tests

;;;; Atoms

(test shallow-copy-atoms
  "Test shallow copying of atomic types like NUMBER, CHARACTER and SYMBOL."

  (is (= 1 (shallow-copy 1)))
  (is (char= #\c (shallow-copy #\c)))
  (is (eq 'hello (shallow-copy 'hello))))

(test deep-copy-atoms
  "Test deep copying of atomic types like NUMBER, CHARACTER and SYMBOL."

  (is (= 1 (deep-copy 1)))
  (is (char= #\c (deep-copy #\c)))
  (is (eq 'hello (deep-copy 'hello))))


;;;; Lists

(test shallow-copy-list
  "Test SHALLOW-COPY on lists."

  (let* ((list '("a" "b" ("c" "d")))
	 (copy (shallow-copy list)))

    (is (not (eq copy list))
	"List not copied.")

    (is (equal '("a" "b" ("c" "d")) copy))

    (is (every #'eq list copy)
	"Copied list is not a shallow copy.")))

(test deep-copy-list
  "Test DEEP-COPY on lists."

  (let* ((list '("a" "b" ("c" "d")))
	 (copy (deep-copy list)))

    (is (not (eq copy list))
	"List not copied.")

    (is (equal '("a" "b" ("c" "d")) copy))

    (is (notany #'eq list copy)
	"Copied list is not a deep copy.")))


;;;; Vectors/Simple Arrays

(test shallow-copy-vector
  "Test SHALLOW-COPY on simple arrays and vectors."

  (let* ((vec #("1" "2" #("3" "4")))
	 (copy (shallow-copy vec)))

    (is (not (eq vec copy))
	"Vector not copied.")

    (is (equalp #("1" "2" #("3" "4")) copy))

    (is (every #'eq vec copy)
	"Copied vector is not a shallow copy.")))

(test deep-copy-vector
  "Test DEEP-COPY on simple arrays and vectors."

  (let* ((vec #("1" "2" #("3" "4")))
	 (copy (deep-copy vec)))

    (is (not (eq vec copy))
	"Vector not copied.")

    (is (equalp #("1" "2" #("3" "4")) copy))

    (is (notany #'eq vec copy)
	"Copied vector is not a deep copy.")))

(test shallow-copy-vector-element-type
  "Test SHALLOW-COPY on vectors with element type."

  (let* ((vec (make-array 3 :element-type 'fixnum :initial-contents '(1 2 3)))
	 (copy (shallow-copy vec)))

    (is (not (eq vec copy))
	"Vector not copied")

    (is (equalp #(1 2 3) copy))

    (is (eq (array-element-type vec)
	    (array-element-type copy)))))

(test deep-copy-vector-element-type
  "Test DEEP-COPY on vectors with element type."

  (let* ((vec (make-array 3 :element-type 'fixnum :initial-contents '(1 2 3)))
	 (copy (deep-copy vec)))

    (is (not (eq vec copy))
	"Vector not copied")

    (is (equalp #(1 2 3) copy))

    (is (eq (array-element-type vec)
	    (array-element-type copy)))))

;;;; Strings

(test shallow-copy-string
  "Test SHALLOW-COPY on strings."

  (let* ((vec "Hello World")
	 (copy (shallow-copy vec)))

    (is (not (eq vec copy))
	"String not copied.")

    (is (equal "Hello World" copy))

    (is (eq 'character (array-element-type copy)))
    (is (not (adjustable-array-p copy)))
    (is (not (array-has-fill-pointer-p copy)))))

(test deep-copy-string
  "Test DEEP-COPY on strings."

  (let* ((vec "Hello World")
	 (copy (deep-copy vec)))

    (is (not (eq vec copy))
	"String not copied.")

    (is (equal "Hello World" copy))

    (is (eq 'character (array-element-type copy)))
    (is (not (adjustable-array-p copy)))
    (is (not (array-has-fill-pointer-p copy)))))


;;;; Single-Dimensional Adjustable Arrays

(test shallow-copy-array
  "Test SHALLOW-COPY on adjustable arrays with a fill pointer."

  (let* ((array (make-array 3 :adjustable t :fill-pointer t :initial-contents '("1" "2" #("3" "4"))))
	 (copy (shallow-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #("1" "2" #("3" "4")) copy))

    (is (adjustable-array-p copy))
    (is (array-has-fill-pointer-p copy))

    (is (every #'eq array copy)
	"Copied array is not a shallow copy.")))

(test deep-copy-array
  "Test DEEP-COPY on adjustable arrays with a fill pointer."

  (let* ((array (make-array 3 :adjustable t :fill-pointer t :initial-contents '("1" "2" #("3" "4"))))
	 (copy (deep-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #("1" "2" #("3" "4")) copy))

    (is (adjustable-array-p copy))
    (is (array-has-fill-pointer-p copy))

    (is (notany #'eq array copy)
	"Copied array is not a deep copy.")))


;;; Multi-Dimensional Arrays

(test shallow-copy-nd-array
  "Test SHALLOW-COPY on multi-dimensional array."

  (let* ((array #2A(("1" "2" "3") ("4" "5" "6")))
	 (copy (shallow-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #2A(("1" "2" "3") ("4" "5" "6")) copy))

    (is (loop for i from 0 below (array-total-size array)
	   always (eq (row-major-aref array i)
		      (row-major-aref copy i)))

	"Copied array is not a shallow copy.")))

(test deep-copy-nd-array
  "Test DEEP-COPY on multi-dimensional array."

  (let* ((array #2A(("1" "2" "3") ("4" "5" "6")))
	 (copy (deep-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #2A(("1" "2" "3") ("4" "5" "6")) copy))

    (is (loop for i from 0 below (array-total-size array)
	   never (eq (row-major-aref array i)
		      (row-major-aref copy i)))

	"Copied array is not a deep copy.")))

(test shallow-copy-nd-array-element-type
  "Test SHALLOW-COPY on multi-dimensional array with element-type."

  (let* ((array (make-array '(2 3) :element-type 'fixnum :initial-contents '((1 2 3) (4 5 6))))
	 (copy (shallow-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #2A((1 2 3) (4 5 6)) copy))

    (is (eq (array-element-type array)
	    (array-element-type copy)))))

(test deep-copy-nd-array-element-type
  "Test DEEP-COPY on multi-dimensional array with element-type."

  (let* ((array (make-array '(2 3) :element-type 'fixnum :initial-contents '((1 2 3) (4 5 6))))
	 (copy (deep-copy array)))

    (is (not (eq array copy))
	"Array not copied.")

    (is (equalp #2A((1 2 3) (4 5 6)) copy))

    (is (eq (array-element-type array)
	    (array-element-type copy)))))


;;;; Hash Tables

(test shallow-copy-hash-table
  "Test SHALLOW-COPY on hash tables."

  (let* ((table (alist-hash-table '((a . "a") (b . "b") (c . "c")) :test #'equalp))
	 (copy (shallow-copy table)))

    (is (not (eq table copy))
	"Hash table not copied.")

    (is (set-equal '((a . "a") (b . "b") (c . "c"))
		   (hash-table-alist copy)
		   :test #'equal))

    (is (eq (hash-table-test copy) (hash-table-test table)))

    (is (loop
	   for key being each hash-key of copy using (hash-value value)
	   always (eq (gethash key table) value))

	"Copied hash-table not a shallow copy.")))

(test deep-copy-hash-table
  "Test DEEP-COPY on hash tables."

  (let* ((table (alist-hash-table '((a . "a") (b . "b") (c . "c")) :test #'equalp))
	 (copy (deep-copy table)))

    (is (not (eq table copy))
	"Hash table not copied.")

    (is (set-equal '((a . "a") (b . "b") (c . "c"))
		   (hash-table-alist copy)
		   :test #'equal))

    (is (eq (hash-table-test copy) (hash-table-test table)))

    (is (loop
	   for key being each hash-key of copy using (hash-value value)
	   never (eq (gethash key table) value))

	"Copied hash-table not a deep copy.")))