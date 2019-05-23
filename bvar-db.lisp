; GL - A Symbolic Simulation Framework for ACL2
; Copyright (C) 2008-2013 Centaur Technology
;
; Contact:
;   Centaur Technology Formal Verification Group
;   7600-C N. Capital of Texas Highway, Suite 300, Austin, TX 78731, USA.
;   http://www.centtech.com/
;
; License: (An MIT/X11-style license)
;
;   Permission is hereby granted, free of charge, to any person obtaining a
;   copy of this software and associated documentation files (the "Software"),
;   to deal in the Software without restriction, including without limitation
;   the rights to use, copy, modify, merge, publish, distribute, sublicense,
;   and/or sell copies of the Software, and to permit persons to whom the
;   Software is furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in
;   all copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;   DEALINGS IN THE SOFTWARE.
;
; Original author: Sol Swords <sswords@centtech.com>

(in-package "FGL")
(include-book "std/basic/arith-equiv-defs" :dir :system)
(include-book "std/stobjs/absstobjs" :dir :system)
(include-book "std/basic/defs" :dir :system)
(include-book "centaur/misc/prev-stobj-binding" :dir :system)
;; (include-book "std/lists/index-of" :dir :system)
(local (include-book "std/basic/arith-equivs" :dir :system))
(local (include-book "std/lists/final-cdr" :dir :system))
(local (include-book "std/lists/resize-list" :dir :system))
(local (include-book "arithmetic/top-with-meta" :dir :system))
(local (include-book "std/lists/nth" :dir :system))

(local (in-theory (enable* acl2::arith-equiv-forwarding)))

(local (in-theory (disable nth update-nth acl2::nth-when-zp)))


;; ----------- Implementation ----------------
;; The "terms" stored in the bvar-db$c are really g-apply objects
(defstobj bvar-db$c
  (base-bvar$c :type (integer 0 *) :initially 0)
  (next-bvar$c :type (integer 0 *) :initially 0)
  (bvar-terms$c :type (array t (0)) :resizable t)
  (term-bvars$c :type t)
  (term-equivs$c :type t))

(defun get-term->bvar$c (x bvar-db$c)
  (declare (xargs :stobjs bvar-db$c))
  (cdr (hons-get x (term-bvars$c bvar-db$c))))

(defun bvar-db-wfp$c (bvar-db$c)
  (declare (xargs :stobjs bvar-db$c))
  (and (<= (lnfix (base-bvar$c bvar-db$c))
           (lnfix (next-bvar$c bvar-db$c)))
       (<= (- (lnfix (next-bvar$c bvar-db$c))
              (lnfix (base-bvar$c bvar-db$c)))
           (bvar-terms$c-length bvar-db$c))))

(defun get-bvar->term$c (n bvar-db$c)
  (declare (type (integer 0 *) n)
           (xargs :stobjs bvar-db$c
                  :guard (and (<= (base-bvar$c bvar-db$c) n)
                              (< n (next-bvar$c bvar-db$c))
                              (bvar-db-wfp$c bvar-db$c))))
  (bvar-terms$ci (- (lnfix n) (lnfix (base-bvar$c bvar-db$c))) bvar-db$c))

(defcong acl2::nat-equiv equal (get-bvar->term$c n bvar-db$c) 1)

(defun add-term-bvar$c (x bvar-db$c)
  (declare (xargs :stobjs bvar-db$c
                  :guard (bvar-db-wfp$c bvar-db$c)))
  (b* ((next (the (integer 0 *) (lnfix (next-bvar$c bvar-db$c))))
       (idx (the (integer 0 *) (lnfix (- next (lnfix (base-bvar$c bvar-db$c))))))
       (terms-len (the (integer 0 *) (bvar-terms$c-length bvar-db$c)))
       (bvar-db$c (if (mbe :logic (<= terms-len idx)
                           :exec (int= terms-len idx))
                      (resize-bvar-terms$c
                       (max 16 (* 2 terms-len)) bvar-db$c)
                    bvar-db$c))
       (bvar-db$c (update-bvar-terms$ci idx x bvar-db$c))
       (bvar-db$c (update-next-bvar$c (+ 1 next) bvar-db$c)))
    (update-term-bvars$c
     (hons-acons (hons-copy x) next (term-bvars$c bvar-db$c))
     bvar-db$c)))

(defthm get-term->bvar$c-of-add-term-bvar$c
  (equal (get-term->bvar$c x (add-term-bvar$c y bvar-db$c))
         (if (equal x y)
             (nfix (next-bvar$c bvar-db$c))
           (get-term->bvar$c x bvar-db$c))))

(defthm term-equivs$c-of-add-term-bvar$c
  (equal (term-equivs$c (add-term-bvar$c y bvar-db$c))
         (term-equivs$c bvar-db$c)))

(defthm get-bvar->term$c-of-add-term-bvar$c
  (implies (and (<= (nfix (base-bvar$c bvar-db$c)) (nfix n))
                (<= (nfix (base-bvar$c bvar-db$c))
                    (nfix (next-bvar$c bvar-db$c))))
           (equal (get-bvar->term$c n (add-term-bvar$c x bvar-db$c))
                  (if (equal (nfix n) (nfix (next-bvar$c bvar-db$c)))
                      x
                    (get-bvar->term$c n bvar-db$c)))))



(defthm base-bvar$c-of-add-term-bvar$c
  (equal (nth *base-bvar$c* (add-term-bvar$c x bvar-db$c))
         (nth *base-bvar$c* bvar-db$c)))

(defthm next-bvar$c-of-add-term-bvar$c
  (equal (nth *next-bvar$c* (add-term-bvar$c x bvar-db$c))
         (+ 1 (nfix (nth *next-bvar$c* bvar-db$c)))))

(defthm bvar-db-wfp$c-of-add-term-bvar$c
  (implies (bvar-db-wfp$c bvar-db$c)
           (bvar-db-wfp$c (add-term-bvar$c x bvar-db$c))))

;; (defun add-term-equiv$c (x n bvar-db$c)
;;   (declare (xargs :stobjs bvar-db$c
;;                   :guard (and (integerp n)
;;                               (<= (base-bvar$c bvar-db$c) n)
;;                               (< n (next-bvar$c bvar-db$c))
;;                               (bvar-db-wfp$c bvar-db$c))))
;;   (b* ((term-equivs (term-equivs$c bvar-db$c)))
;;     (update-term-equivs$c (hons-acons x (cons n (cdr (hons-get x term-equivs)))
;;                                       term-equivs)
;;                           bvar-db$c)))

(defthm get-term->bvar$c-of-update-term-equivs$c
  (equal (get-term->bvar$c x (update-term-equivs$c q bvar-db$c))
         (get-term->bvar$c x bvar-db$c)))

(defthm term-equivs$c-of-update-term-equivs$c
  (equal (term-equivs$c (update-term-equivs$c q bvar-db$c))
         q))
;; (defthm get-term->bvar$c-of-add-term-equiv$c
;;   (equal (get-term->bvar$c x (add-term-equiv$c y n bvar-db$c))
;;          (get-term->bvar$c x bvar-db$c)))

;; (defthm get-term->equivs$c-of-add-term-equiv$c
;;   (equal (term-equivs$c (add-term-equiv$c y n bvar-db$c))
;;          (hons-acons x (cons n (get-term->equivs$c x bvar-db$c))
;;                      (term-equivs$c bvar-db$c))))


(defthm get-bvar->term$c-of-update-term-equivs$c
  (equal (get-bvar->term$c x (update-term-equivs$c q bvar-db$c))
         (get-bvar->term$c x bvar-db$c)))

(defthm base-bvar$c-of-update-term-equivs$c
  (equal (nth *base-bvar$c* (update-term-equivs$c q bvar-db$c))
         (nth *base-bvar$c* bvar-db$c)))

(defthm next-bvar$c-of-update-term-equivs$c
  (equal (nth *next-bvar$c* (update-term-equivs$c q bvar-db$c))
         (nth *next-bvar$c* bvar-db$c)))


(defthm bvar-db-wfp$c-of-update-term-equivs$c
  (implies (bvar-db-wfp$c bvar-db$c)
           (bvar-db-wfp$c (update-term-equivs$c q bvar-db$c))))



;; (defthm get-bvar->term$c-of-add-term-equiv$c
;;   (equal (get-bvar->term$c x (add-term-equiv$c y n bvar-db$c))
;;          (get-bvar->term$c x bvar-db$c)))

;; (defthm base-bvar$c-of-add-term-equiv$c
;;   (equal (nth *base-bvar$c* (add-term-equiv$c x n bvar-db$c))
;;          (nth *base-bvar$c* bvar-db$c)))

;; (defthm next-bvar$c-of-add-term-equiv$c
;;   (equal (nth *next-bvar$c* (add-term-equiv$c x n bvar-db$c))
;;          (nth *next-bvar$c* bvar-db$c)))


;; (defthm bvar-db-wfp$c-of-add-term-equiv$c
;;   (implies (bvar-db-wfp$c bvar-db$c)
;;            (bvar-db-wfp$c (add-term-equiv$c x n bvar-db$c))))



(defun init-bvar-db$c (base-bvar bvar-db$c)
  (declare (type (integer 0 *) base-bvar)
           (xargs :stobjs bvar-db$c))
  (b* ((bvar-db$c (update-base-bvar$c (lnfix base-bvar) bvar-db$c))
       (bvar-db$c (update-next-bvar$c (lnfix base-bvar) bvar-db$c))
       (bvar-db$c (update-term-equivs$c nil bvar-db$c)))
    (update-term-bvars$c nil bvar-db$c)))

(defthm base-bvar$c-of-init-bvar-db$c
  (equal (nth *base-bvar$c* (init-bvar-db$c base bvar-db$c))
         (nfix base)))

(defthm term-equivs$c-of-init-bvar-db$c
  (equal (term-equivs$c (init-bvar-db$c base-bvar bvar-db$c))
         nil))

(defthm next-bvar$c-of-init-bvar-db$c
  (equal (nth *next-bvar$c* (init-bvar-db$c base bvar-db$c))
         (nfix base)))

(defthm get-term->bvar-of-init-bvar-db$c
  (equal (get-term->bvar$c x (init-bvar-db$c base bvar-db$c))
         nil))

(defthm bvar-db-wfp$c-of-init-bvar-db$c
  (bvar-db-wfp$c (init-bvar-db$c base bvar-db$c)))


(defthm create-bvar-db$c-rewrite
  (equal (create-bvar-db$c)
         (init-bvar-db$c 0 '(0 0 nil nil nil))))

(local (in-theory (disable (create-bvar-db$c) create-bvar-db$c)))


(defund bvar-listp$c (x bvar-db$c)
  (declare (xargs :stobjs bvar-db$c))
  (if (atom x)
      (eq x nil)
    (and (natp (car x))
         (<= (base-bvar$c bvar-db$c) (car x))
         (< (car x) (next-bvar$c bvar-db$c))
         (bvar-listp$c (cdr x) bvar-db$c))))

(defund term-equivsp$c (equivs bvar-db$c)
  (declare (xargs :stobjs bvar-db$c))
  (if (atom equivs)
      (eq equivs nil)
    (and (consp (car equivs))
         (bvar-listp$c (cdar equivs) bvar-db$c)
         (term-equivsp$c (cdr equivs) bvar-db$c))))

;; ------------------ Logic ----------------

;; (encapsulate
;;   ;; (((next-bvar$a *) => *
;;   ;;   :formals (bvar-db$a)
;;   ;;   :guard t)
;;   ;;  ((base-bvar$a *) => *
;;   ;;   :formals (bvar-db$a)
;;   ;;   :guard t)
;;   ;;  ((get-bvar->term$a * *) => *
;;   ;;   :formals (n bvar-db$a)
;;   ;;   :guard (and (natp n)
;;   ;;               (<= (base-bvar$a bvar-db$a) n)
;;   ;;               (< n (next-bvar$a bvar-db$a))))
;;   ;;  ((get-term->bvar$a * *) => *
;;   ;;   :formals (x bvar-db$a)
;;   ;;   :guard t)
;;   ;;  ((add-term-bvar$a * *) => *
;;   ;;   :formals (x bvar-db$a)
;;   ;;   :guard (not (get-term->bvar$a x bvar-db$a)))
;;   ;;  ((init-bvar-db$a * *) => *
;;   ;;   :formals (base bvar-db$a)
;;   ;;   :guard (natp base)))

;;   (defund init-bvar-db$a (base bvar-db$a)
;;     (declare (ignore bvar-db$a))
;;     (cons (nfix base) nil))

;;   (defund base-bvar$a (bvar-db$a)
;;     (nfix (car bvar-db$a)))

;;   (defund next-bvar$a (bvar-db$a)
;;     (+ (base-bvar$a bvar-db$a)
;;        (len (cdr bvar-db$a))))

;;   (defund get-bvar->term$a (n bvar-db$a)
;;     (nth (- (nfix n) (base-bvar$a bvar-db$a))
;;          (cdr bvar-db$a)))

;;   (defund get-term->bvar$a (x bvar-db$a)
;;     (let ((idx (acl2::index-of x (cdr bvar-db$a))))
;;       (and idx (+ idx (base-bvar$a bvar-db$a)))))

;;   (defund add-term-bvar$a (x bvar-db$a)
;;     (cons (car bvar-db$a)
;;           (append (cdr bvar-db$a) (list x))))

;;   (local (in-theory (enable init-bvar-db$a
;;                             base-bvar$a
;;                             next-bvar$a
;;                             get-bvar->term$a
;;                             get-term->bvar$a
;;                             add-term-bvar$a)))

;;   (defthm type-of-base-bvar$a
;;     (natp (base-bvar$a bvar-db$a))
;;     :rule-classes :type-prescription)

;;   (defthm type-of-next-bvar$a
;;     (natp (next-bvar$a bvar-db$a))
;;     :rule-classes :type-prescription)

;;   (defthm type-of-get-term->bvar$a
;;     (or (not (get-term->bvar$a x bvar-db$a))
;;         (natp (get-term->bvar$a x bvar-db$a)))
;;     :rule-classes :type-prescription)

;;   (defthm next-bvar-gte-base-bvar$a
;;     (<= (base-bvar$a bvar-db$a) (next-bvar$a bvar-db$a))
;;     :rule-classes (:rewrite :linear))

;;   (defthm term-bvar-gte-base-bvar$a
;;     (implies (get-term->bvar$a x bvar-db$a)
;;              (<= (base-bvar$a bvar-db$a)
;;                  (get-term->bvar$a x bvar-db$a)))
;;     :rule-classes (:rewrite :linear))

;;   ;; this is probably derivable
;;   (defthm term-bvar-less-than-next-bvar$a
;;     (implies (get-term->bvar$a x bvar-db$a)
;;              (< (get-term->bvar$a x bvar-db$a)
;;                 (next-bvar$a bvar-db$a)))
;;     :rule-classes (:rewrite :linear))

;;   (defthm init-bvar-db$a-normalize
;;     (implies (syntaxp (not (equal bvar-db$a ''nil)))
;;              (equal (init-bvar-db$a base bvar-db$a)
;;                     (init-bvar-db$a base nil))))

;;   (defthm base-bvar-of-init-bvar-db$a
;;     (equal (base-bvar$a (init-bvar-db$a base bvar-db$a))
;;            (nfix base)))

;;   (defthm next-bvar-of-init-bvar-db$a
;;     (equal (next-bvar$a (init-bvar-db$a base bvar-db$a))
;;            (nfix base)))

;;   (defthm get-term->bvar-of-init-bvar-db$a
;;     (equal (get-term->bvar$a x (init-bvar-db$a base bvar-db$a))
;;            nil))

;;   (defthm base-bvar$a-of-add-term-bvar$a
;;     (equal (base-bvar$a (add-term-bvar$a x bvar-db$a))
;;            (base-bvar$a bvar-db$a)))

;;   (local (defthm len-append
;;            (equal (len (append a b))
;;                   (+ (len a) (len b)))))

;;   (defthm next-bvar$a-of-add-term-bvar$a
;;     (equal (next-bvar$a (add-term-bvar$a x bvar-db$a))
;;            (+ 1 (next-bvar$a bvar-db$a))))

;;   (defthm get-bvar->term$a-of-add-term-bvar$a-existing
;;     (implies (and (<= (base-bvar$a bvar-db$a) (nfix n))
;;                   (not (equal (nfix n) (next-bvar$a bvar-db$a))))
;;              (equal (get-bvar->term$a n (add-term-bvar$a x bvar-db$a))
;;                     (get-bvar->term$a n bvar-db$a))))

;;   (defthm get-bvar->term$a-of-add-term-bvar$a-new
;;     (implies (and (<= (base-bvar$a bvar-db$a) (nfix n))
;;                   (equal (nfix n) (next-bvar$a bvar-db$a)))
;;              (equal (get-bvar->term$a n (add-term-bvar$a x bvar-db$a))
;;                     x)))

;;   (defthm get-term->bvar$a-of-add-term-bvar$a-other
;;     (implies (not (equal x y))
;;              (equal (get-term->bvar$a y (add-term-bvar$a x bvar-db$a))
;;                     (get-term->bvar$a y bvar-db$a)))
;;     :hints(("Goal" :in-theory (enable acl2::index-of-append-split))))

;;   (defthm get-term->bvar$a-of-add-term-bvar$a-new
;;     (implies (not (get-term->bvar$a x bvar-db$a))
;;              (equal (get-term->bvar$a x (add-term-bvar$a x bvar-db$a))
;;                     (next-bvar$a bvar-db$a)))))

(encapsulate
  (((next-bvar$a *) => *
    :formals (bvar-db$a)
    :guard t)
   ((base-bvar$a *) => *
    :formals (bvar-db$a)
    :guard t)
   ((get-bvar->term$a * *) => *
    :formals (n bvar-db$a)
    :guard (and (natp n)
                (<= (base-bvar$a bvar-db$a) n)
                (< n (next-bvar$a bvar-db$a))))
   ((get-term->bvar$a * *) => *
    :formals (x bvar-db$a)
    :guard t)
   ((add-term-bvar$a * *) => *
    :formals (x bvar-db$a)
    :guard t)
   ((term-equivs$a *) => *
    :formals (bvar-db$a)
    :guard t)
   ((bvar-listp$a * *) => *
    :formals (x bvar-db$a)
    :guard t)
   ((term-equivsp$a * *) => *
    :formals (equivs bvar-db$a)
    :guard t)
   ((update-term-equivs$a * *) => *
    :formals (equivs bvar-db$a)
    :guard (term-equivsp$a equivs bvar-db$a))
   ((init-bvar-db$a * *) => *
    :formals (base bvar-db$a)
    :guard (natp base)))

  (local
   (progn


     (defund init-bvar-db$a (base bvar-db$a)
       (declare (ignore bvar-db$a)
                (xargs :guard t))
       (cons (nfix base) nil))

     (defund base-bvar$a (bvar-db$a)
       (declare (xargs :guard t))
       (nfix (acl2::final-cdr (ec-call (car bvar-db$a)))))

     (defund next-bvar$a (bvar-db$a)
       (declare (xargs :guard t))
       (+ (base-bvar$a bvar-db$a) (len (ec-call (car bvar-db$a)))))

     (defund filter-bvars (x bvar-db$a)
       (declare (xargs :guard t))
       (if (atom x)
           nil
         (if (and (natp (car x))
                  (<= (base-bvar$a bvar-db$a) (car x))
                  (< (car x) (next-bvar$a bvar-db$a)))
             (cons (car x) (filter-bvars (cdr x) bvar-db$a))
           (filter-bvars (cdr x) bvar-db$a))))

     (defund filter-equivs (x bvar-db$a)
       (declare (xargs :guard t))
       (if (atom x)
           nil
         (if (consp (car x))
             (cons (cons (caar x) (filter-bvars (cdar x) bvar-db$a))
                   (filter-equivs (cdr x) bvar-db$a))
           (filter-equivs (cdr x) bvar-db$a))))

     (defund get-bvar->term$a (n bvar-db$a)
       (declare (xargs :guard (and (natp n)
                                   (<= (base-bvar$a bvar-db$a) n)
                                   (< n (next-bvar$a bvar-db$a)))))
       (and (< (nfix n) (next-bvar$a bvar-db$a))
            (ec-call (nth (+ -1 (len (ec-call (car bvar-db$a))) (base-bvar$a bvar-db$a) (- (nfix n) ))
                          (ec-call (car bvar-db$a))))))

     (defund term-equivs$a (bvar-db$a)
       (declare (xargs :guard t))
       (filter-equivs (ec-call (cdr bvar-db$a)) bvar-db$a))


     (defund bvar-listp$a (x bvar-db$a)
       (declare (xargs :guard t))
       (if (atom x)
           (eq x nil)
         (and (natp (car x))
              (<= (base-bvar$a bvar-db$a) (car x))
              (< (car x) (next-bvar$a bvar-db$a))
              (bvar-listp$a (cdr x) bvar-db$a))))

     (defund term-equivsp$a (equivs bvar-db$a)
       (declare (xargs :guard t))
       (if (atom equivs)
           (eq equivs nil)
         (and (consp (car equivs))
              (bvar-listp$a (cdar equivs) bvar-db$a)
              (term-equivsp$a (cdr equivs) bvar-db$a))))

     (defund update-term-equivs$a (equivs bvar-db$a)
       (declare (xargs :guard (term-equivsp$a equivs bvar-db$a)))
       (cons (ec-call (car bvar-db$a))
             (filter-equivs equivs bvar-db$a)))

     (defund get-term->bvar$a (x bvar-db$a)
       (declare (xargs :guard t))
       (let ((suff (ec-call (member-equal x (ec-call (car bvar-db$a))))))
         (and suff (+ -1 (len suff) (base-bvar$a bvar-db$a)))))

     (defund add-term-bvar$a (x bvar-db$a)
       (declare (xargs :guard t))
       (cons (cons x (ec-call (car bvar-db$a)))
             (filter-equivs (ec-call (cdr bvar-db$a)) bvar-db$a)))))

  (defthm bvar-listp$a-def
    (equal (bvar-listp$a x bvar-db$a)
           (if (atom x)
               (eq x nil)
             (and (natp (car x))
                  (<= (base-bvar$a bvar-db$a) (car x))
                  (< (car x) (next-bvar$a bvar-db$a))
                  (bvar-listp$a (cdr x) bvar-db$a))))
    :hints(("Goal" :in-theory (enable bvar-listp$a)))
    :rule-classes ((:definition :controller-alist ((bvar-listp$a t nil)))))

  (defthm term-equivsp$a-def
    (equal (term-equivsp$a equivs bvar-db$a)
           (if (atom equivs)
               (eq equivs nil)
             (and (consp (car equivs))
                  (bvar-listp$a (cdar equivs) bvar-db$a)
                  (term-equivsp$a (cdr equivs) bvar-db$a))))
    :hints(("Goal" :in-theory (enable term-equivsp$a)))
    :rule-classes ((:definition :controller-alist ((term-equivsp$a t nil)))))


  (local (in-theory (enable init-bvar-db$a
                            base-bvar$a
                            next-bvar$a
                            get-bvar->term$a
                            get-term->bvar$a
                            add-term-bvar$a
                            term-equivs$a
                            update-term-equivs$a)))

  (defcong acl2::nat-equiv equal (get-bvar->term$a n bvar-db$a) 1)
  (defcong acl2::nat-equiv equal (init-bvar-db$a n bvar-db$a) 1)

  (defthm type-of-base-bvar$a
    (natp (base-bvar$a bvar-db$a))
    :rule-classes :type-prescription)

  (defthm type-of-next-bvar$a
    (natp (next-bvar$a bvar-db$a))
    :rule-classes :type-prescription)

  (local (defthm equal-len-0
           (equal (equal (len x) 0)
                  (not (consp x)))))

  (defthm type-of-get-term->bvar$a
    (or (not (get-term->bvar$a x bvar-db$a))
        (natp (get-term->bvar$a x bvar-db$a)))
    :rule-classes :type-prescription)

  (local (defthm bvar-listp$a-of-filter-bvars
           (bvar-listp$a (filter-bvars x bvar-db$a) bvar-db$a)
           :hints(("Goal" :in-theory (enable filter-bvars)))))

  (local (defthm nat-listp-of-filter-bvars
           (acl2::nat-listp (filter-bvars x bvar-db$a))
           :hints(("Goal" :in-theory (enable filter-bvars)))))

  (local (defthm term-equivsp$a-of-filter-equivs
           (term-equivsp$a (filter-equivs x bvar-db$a) bvar-db$a)
           :hints(("Goal" :in-theory (enable filter-equivs)))))

  (local (defthm lookup-of-filter-equivs
           (equal (cdr (hons-assoc-equal x (filter-equivs y bvar-db$a)))
                  (filter-bvars (cdr (hons-assoc-equal x y)) bvar-db$a))
           :hints(("Goal" :in-theory (enable filter-equivs)
                   :induct t)
                  (and stable-under-simplificationp
                       '(:in-theory (enable filter-bvars))))))

  (defthm next-bvar-gte-base-bvar$a
    (<= (base-bvar$a bvar-db$a) (next-bvar$a bvar-db$a))
    :rule-classes (:rewrite :linear))

  (defthm term-bvar-gte-base-bvar$a
    (implies (get-term->bvar$a x bvar-db$a)
             (<= (base-bvar$a bvar-db$a)
                 (get-term->bvar$a x bvar-db$a)))
    :rule-classes (:rewrite :linear))

  (local (defthm len-member
           (<= (len (member x y)) (len y))
           :rule-classes :linear))

  (defthm term-bvar-less-than-next-bvar$a
    (implies (get-term->bvar$a x bvar-db$a)
             (< (get-term->bvar$a x bvar-db$a)
                (next-bvar$a bvar-db$a)))
    :rule-classes (:rewrite :linear))

  (defthm term-equivsp$a-of-term-equivs$a
    (term-equivsp$a (term-equivs$a bvar-db) bvar-db))

  (defthm bvar-listp$a-of-lookup
    (implies (term-equivsp$a q bvar-db$a)
             (bvar-listp$a (cdr (hons-assoc-equal x q)) bvar-db$a)))

  ;; (local (defun nth-filter-ind (n x bvar-db$a)
  ;;          (if (atom x)
  ;;              n
  ;;            (nth-filter-ind (if (and (natp (car x))
  ;;                                     (<= (base-bvar$a bvar-db$a) (car x))
  ;;                                     (< (car x) (next-bvar$a bvar-db$a)))
  ;;                                (1- n)
  ;;                              n)
  ;;                            (cdr x) bvar-db$a))))


  ;; (local (defthm nth-filter-bvars-gte-base-bvar$a
  ;;          (implies (< (nfix n) (len (filter-bvars x bvar-db$a)))
  ;;                   (<= (base-bvar$a bvar-db$a) (nth n (filter-bvars x bvar-db$a))))
  ;;          :hints(("Goal" :in-theory (enable filter-bvars nth)
  ;;                  :induct (nth-filter-ind n x bvar-db$a)))
  ;;          :rule-classes :linear))

  ;; (defthm term-equiv-gte-base-bvar$a
  ;;   (implies (< (nfix n) (len (get-term->equivs$a x bvar-db$a)))
  ;;            (<= (base-bvar$a bvar-db$a) (nth n (get-term->equivs$a x bvar-db$a))))
  ;;          :rule-classes :linear)

  ;; (local (defthm nth-filter-bvars-less-than-next-bvar$a
  ;;          (implies (< (nfix n) (len (filter-bvars x bvar-db$a)))
  ;;                   (< (nth n (filter-bvars x bvar-db$a)) (next-bvar$a bvar-db$a)))
  ;;          :hints(("Goal" :in-theory (enable filter-bvars nth)
  ;;                  :induct (nth-filter-ind n x bvar-db$a)))
  ;;          :rule-classes :linear))

  ;; (defthm term-equiv-less-than-next-bvar$a
  ;;   (implies (< (nfix n) (len (get-term->equivs$a x bvar-db$a)))
  ;;            (< (nth n (get-term->equivs$a x bvar-db$a)) (next-bvar$a bvar-db$a))))

  (defthm init-bvar-db$a-normalize
    (implies (syntaxp (not (equal bvar-db$a ''nil)))
             (equal (init-bvar-db$a base bvar-db$a)
                    (init-bvar-db$a base nil))))

  (defthm base-bvar-of-init-bvar-db$a
    (equal (base-bvar$a (init-bvar-db$a base bvar-db$a))
           (nfix base)))

  (defthm next-bvar-of-init-bvar-db$a
    (equal (next-bvar$a (init-bvar-db$a base bvar-db$a))
           (nfix base)))

  (defthm get-term->bvar-of-init-bvar-db$a
    (equal (get-term->bvar$a x (init-bvar-db$a base bvar-db$a))
           nil))

  (defthm term->equivs-of-init-bvar-db$a
    (equal (term-equivs$a (init-bvar-db$a base bvar-db$a))
           nil)
    :hints(("Goal" :in-theory (enable filter-bvars filter-equivs))))

  (defthm base-bvar$a-of-add-term-bvar$a
    (equal (base-bvar$a (add-term-bvar$a x bvar-db$a))
           (base-bvar$a bvar-db$a)))

  (local (defthm len-append
           (equal (len (append a b))
                  (+ (len a) (len b)))))

  (defthm base-bvar$a-of-update-term-equivs$a
    (equal (base-bvar$a (update-term-equivs$a x bvar-db$a))
           (base-bvar$a bvar-db$a)))

  (defthm next-bvar$a-of-update-term-equivs$a
    (equal (next-bvar$a (update-term-equivs$a x bvar-db$a))
           (next-bvar$a bvar-db$a)))

  (defthm get-term->bvar$a-of-update-term-equivs$a
    (equal (get-term->bvar$a x (update-term-equivs$a q bvar-db$a))
           (get-term->bvar$a x bvar-db$a)))

  (defthm get-bvar->term$a-of-update-term-equivs$a
    (equal (get-bvar->term$a x (update-term-equivs$a q bvar-db$a))
           (get-bvar->term$a x bvar-db$a)))

  (local (defthm filter-bvars-of-filter-bvars
           (implies (equal (car db1) (car db2))
                    (equal (filter-bvars (filter-bvars x db1) db2)
                           (filter-bvars x db1)))
           :hints(("Goal" :in-theory (enable base-bvar$a next-bvar$a
                                             filter-bvars)))))

  (local (defthm filter-bvars-when-bvar-listp$a
           (implies (and (bvar-listp$a q bvar-db2)
                         (equal (car bvar-db2) (car bvar-db$a)))
                    (equal (filter-bvars q bvar-db$a)
                           q))
           :hints(("Goal" :in-theory (enable filter-bvars)))))

  (local (defthm filter-equivs-when-term-equivsp$a
           (implies (and (term-equivsp$a q bvar-db2)
                         (equal (car bvar-db2) (car bvar-db$a)))
                    (equal (filter-equivs q bvar-db$a)
                           q))
           :hints(("Goal" :in-theory (enable filter-equivs)))))

  (defthm term-equivs-of-update-term-equiv1$a
    (implies (term-equivsp$a q bvar-db$a)
             (equal (term-equivs$a (update-term-equivs$a q bvar-db$a))
                    q)))


  ;; (local (defthm member-remove-duplicates
  ;;          (iff (member k (remove-duplicates-equal x))
  ;;               (member k x))))

  (defthm next-bvar$a-of-add-term-bvar$a-split
    (equal (next-bvar$a (add-term-bvar$a x bvar-db$a))
           (+ 1 (next-bvar$a bvar-db$a))))

  (local (defthm nth-of-cons
           (equal (nth n (cons a b))
                  (if (zp n) a
                    (nth (1- n) b)))
           :hints(("Goal" :in-theory (enable nth)))))

  (defthm get-bvar->term$a-of-add-term-bvar$a-split
    ;; (implies (<= (base-bvar$a bvar-db$a) (nfix n))
    (equal (get-bvar->term$a n (add-term-bvar$a x bvar-db$a))
           (if (equal (nfix n) (next-bvar$a bvar-db$a))
               x
             (get-bvar->term$a n bvar-db$a))))

  ;; (defthm get-bvar->term$a-of-add-term-bvar$a-existing
  ;;   (implies (and (<= (base-bvar$a bvar-db$a) (nfix n))
  ;;                 (not (equal (nfix n) (next-bvar$a bvar-db$a))))
  ;;            (equal (get-bvar->term$a n (mv-nth 1 (add-term-bvar$a x bvar-db$a)))
  ;;                   (get-bvar->term$a n bvar-db$a))))

  ;; (defthm get-bvar->term$a-of-add-term-bvar$a-new
  ;;   (implies (and (<= (base-bvar$a bvar-db$a) (nfix n))
  ;;                 (equal (nfix n) (next-bvar$a bvar-db$a)))
  ;;            (equal (get-bvar->term$a n (add-term-bvar$a x bvar-db$a))
  ;;                   x)))

  (defthm get-term->bvar$a-of-add-term-bvar$a-split
    (equal (get-term->bvar$a y (add-term-bvar$a x bvar-db$a))
           (if (equal x y)
               (next-bvar$a bvar-db$a)
             (get-term->bvar$a y bvar-db$a))))

  (local (defthm filter-bvars-of-filter-bvars-cons
           (equal (filter-bvars (filter-bvars x db1)
                                (cons (cons y (car db1)) z))
                  (filter-bvars x db1))
           :hints(("Goal" :in-theory (enable base-bvar$a next-bvar$a
                                             filter-bvars)))))

  (local (defthm filter-equivs-of-filter-equivs-cons
           (equal (filter-equivs (filter-equivs x db1)
                                 (cons (cons y (car db1)) z))
                  (filter-equivs x db1))
           :hints(("Goal" :in-theory (enable base-bvar$a next-bvar$a
                                             filter-equivs)))))

  (defthm term-equivs-of-add-term-bvar$a
    (equal (term-equivs$a (add-term-bvar$a x bvar-db$a))
           (term-equivs$a bvar-db$a)))

  (local (defthm len-of-member-bound
           (<= (len (member x y)) (len y))
           :rule-classes :linear))

  (local (defthm consp-member-equal
           (iff (consp (member-equal x y))
                (member-equal x y))))

  (local (defthm len-member-when-member
           (implies (member x y)
                    (< 0 (len (member x y))))
           :rule-classes :linear))

  (local (defthm nth-by-member
           (implies (member x z)
                    (equal (nth (+ (len z)
                                   (- (len (member x z))))
                                z)
                           x))
           :hints(("Goal" :in-theory (enable nth member)))))


  (defthm get-bvar->term$a-of-get-term->bvar
    (let ((bvar (get-term->bvar$a x bvar-db$a)))
      (implies bvar
               (equal (get-bvar->term$a bvar bvar-db$a)
                      x))))

  ;; (local (defthm no-duplicatesp-of-remove-duplicates
  ;;          (no-duplicatesp (remove-duplicates-equal x))))

  ;; (local (defthm len-member-nth-when-no-duplicates
  ;;          (implies (and (< (nfix n) (len x))
  ;;                        (no-duplicatesp x))
  ;;                   (equal (len (member (nth n x) x))
  ;;                          (- (len x) (nfix n))))
  ;;          :hints(("Goal" :in-theory (enable nth)))))

  (defthm get-term->bvar$a-of-get-bvar->term
    (let ((term (get-bvar->term$a n bvar-db$a)))
      (implies (and (<= (base-bvar$a bvar-db$a) (nfix n))
                    (< (nfix n) (next-bvar$a bvar-db$a)))
               (get-term->bvar$a term bvar-db$a)))))


(defun create-bvar-db$a ()
  (declare (xargs :guard t))
  (init-bvar-db$a 0 nil))

(defun bvar-db$ap (bvar-db$a)
  (declare (ignore bvar-db$a)
           (xargs :guard t))
  t)


(defun-sk bvar-dbs-terms-corr (bvar-db$c bvar-db$a)
  (forall x
          (and (equal (get-term->bvar$c x bvar-db$c)
                      (get-term->bvar$a x bvar-db$a))
               (equal (term-equivs$c bvar-db$c)
                      (term-equivs$a bvar-db$a))))
  :rewrite :direct)

(defun-sk bvar-dbs-bvars-corr (bvar-db$c bvar-db$a)
  (forall n
          (implies (and (natp n)
                        (<= (base-bvar$a bvar-db$a) n)
                        (< n (next-bvar$a bvar-db$a)))
                   (equal (get-bvar->term$c n bvar-db$c)
                          (get-bvar->term$a n bvar-db$a))))
  :rewrite :direct)

(local (in-theory (disable bvar-dbs-terms-corr
                           bvar-dbs-bvars-corr)))

(defun-nx bvar-dbs-corr (bvar-db$c bvar-db$a)
  (and (equal (base-bvar$c bvar-db$c) (base-bvar$a bvar-db$a))
       (equal (next-bvar$c bvar-db$c) (next-bvar$a bvar-db$a))
       (bvar-dbs-bvars-corr bvar-db$c bvar-db$a)
       (bvar-dbs-terms-corr bvar-db$c bvar-db$a)
       (bvar-db-wfp$c bvar-db$c)))

(defthm bvar-listp$c-is-$a
  (implies (and (bind-free '((bvar-db . bvar-db)) (bvar-db))
                (equal (base-bvar$c bvar-db$c)
                       (base-bvar$a bvar-db))
                (equal (next-bvar$c bvar-db$c)
                       (next-bvar$a bvar-db)))
           (equal (bvar-listp$c x bvar-db$c)
                  (bvar-listp$a x bvar-db)))
  :hints (("goal" :induct (bvar-listp$c x bvar-db$c)
           :in-theory (enable bvar-listp$c))))

(defthm term-equivsp$c-is-$a
  (implies (and (bind-free '((bvar-db . bvar-db)) (bvar-db))
                (equal (base-bvar$c bvar-db$c)
                       (base-bvar$a bvar-db))
                (equal (next-bvar$c bvar-db$c)
                       (next-bvar$a bvar-db)))
           (equal (term-equivsp$c x bvar-db$c)
                  (term-equivsp$a x bvar-db)))
  :hints (("goal" :induct (term-equivsp$c x bvar-db$c)
           :in-theory (enable term-equivsp$c))))


(encapsulate nil
  (local (set-default-hints
          '((and stable-under-simplificationp
                 (let ((lit (car (last clause))))
                   (and (not (eq (car lit) 'equal))
                        `(:expand (,lit))))))))

  (local (in-theory (disable (init-bvar-db$c)
                             init-bvar-db$c
                             get-term->bvar$c
                             add-term-bvar$c
                             get-bvar->term$c
                             update-term-equivs$c
                             term-equivs$c)))

  (acl2::defabsstobj-events bvar-db
    :creator (create-bvar-db :logic create-bvar-db$a :exec create-bvar-db$c)
    :recognizer (bvar-dbp :logic bvar-db$ap :exec bvar-db$cp)
    :corr-fn bvar-dbs-corr
    :exports ((base-bvar :logic base-bvar$a :exec base-bvar$c)
              (next-bvar :logic next-bvar$a :exec next-bvar$c)
              (get-term->bvar :logic get-term->bvar$a :exec get-term->bvar$c)
              (get-bvar->term :logic get-bvar->term$a :exec get-bvar->term$c)
              (term-equivs :logic term-equivs$a :exec term-equivs$c)
              (bvar-listp :logic bvar-listp$a :exec bvar-listp$c)
              (term-equivsp :logic term-equivsp$a :exec term-equivsp$c)
              (add-term-bvar :logic add-term-bvar$a :exec add-term-bvar$c :protect t)
              (update-term-equivs :logic update-term-equivs$a :exec update-term-equivs$c)
              (init-bvar-db :logic init-bvar-db$a :exec init-bvar-db$c :protect t))))



(defun-sk bvar-db-bvar->term-extension-p (new old)
  (forall v
          (implies (and (natp v)
                        (or (< v (next-bvar old))
                            (<= (next-bvar new) v)))
                   (equal (get-bvar->term$a v new)
                          (get-bvar->term$a v old))))
  :rewrite :direct)

(defun-sk bvar-db-term->bvar-extension-p (new old)
  (forall x
          (implies (get-term->bvar$a x old)
                   (equal (get-term->bvar$a x new)
                          (get-term->bvar$a x old))))
  :rewrite :direct)

(in-theory (disable bvar-db-bvar->term-extension-p
                    bvar-db-term->bvar-extension-p))


(defmacro bind-bvar-db-extension (new old-var)
  `(and (bind-free (acl2::prev-stobj-binding ,new ',old-var mfc state))
        (bvar-db-extension-p ,new ,old-var)))



(define bvar-db-extension-p (new old)
  :non-executable t
  :verify-guards nil
  (and (equal (base-bvar$a new) (base-bvar$a old))
       (>= (next-bvar$a new) (next-bvar$a old))
       (bvar-db-bvar->term-extension-p new old)
       (bvar-db-term->bvar-extension-p new old)
       ;; bozo this wouldn't be the right invariant about term-equivs, but it
       ;; seems for now we don't need one.
       ;; (acl2::suffixp (term-equivs$a old) (term-equivs$a new))
       )
  ///
  (defthm bvar-db-extension-preserves-base-bvar
    (implies (bind-bvar-db-extension new old)
             (equal (base-bvar$a new) (base-bvar$a old))))

  (defthm bvar-db-extension-increases
    (implies (bind-bvar-db-extension new old)
             (>= (next-bvar$a new) (next-bvar$a old)))
    :rule-classes ((:linear :trigger-terms ((next-bvar$a new)))))

  (defthm bvar-db-extension-preserves-get-bvar->term
    (implies (and (bind-bvar-db-extension new old)
                  (or (< (nfix v) (next-bvar$a old))
                      (<= (next-bvar$a new) (nfix v))))
             (equal (get-bvar->term$a v new)
                    (get-bvar->term$a v old)))
    :hints (("goal" :use ((:instance bvar-db-bvar->term-extension-p-necc
                           (v (nfix v))))
             :in-theory (disable bvar-db-bvar->term-extension-p-necc))))

  (defthm bvar-db-extension-preserves-get-term->bvar
    (implies (and (bind-bvar-db-extension new old)
                  (get-term->bvar$a x old))
             (equal (get-term->bvar$a x new)
                    (get-term->bvar$a x old))))

  (defthm bvar-db-extension-p-self
    (bvar-db-extension-p x x)
    :hints(("Goal" :in-theory (enable bvar-db-bvar->term-extension-p
                                      bvar-db-term->bvar-extension-p))))

  (local (defthm bvar-db-bvar->term-extension-p-transitive
           (implies (and (bvar-db-bvar->term-extension-p new med)
                         (bvar-db-bvar->term-extension-p med old)
                         (<= (next-bvar$a med) (next-bvar$a new))
                         (<= (next-bvar$a old) (next-bvar$a med)))
                    (bvar-db-bvar->term-extension-p new old))
           :hints ((and stable-under-simplificationp
                        `(:expand (,(car (last clause))))))))

  (local (defthm bvar-db-term->bvar-extension-p-transitive
           (implies (and (bvar-db-term->bvar-extension-p new med)
                         (bvar-db-term->bvar-extension-p med old))
                    (bvar-db-term->bvar-extension-p new old))
           :hints ((and stable-under-simplificationp
                        `(:expand (,(car (last clause))))))))

  (defthm bvar-db-extension-p-transitive
    (implies (and (bind-bvar-db-extension new med)
                  (bvar-db-extension-p med old))
             (bvar-db-extension-p new old)))

  (defthm bvar-db-extension-p-of-add-term-bvar
    (implies (not (get-term->bvar$a x bvar-db))
             (bvar-db-extension-p (add-term-bvar$a x bvar-db) bvar-db))
    :hints(("Goal" :in-theory (enable bvar-db-bvar->term-extension-p
                                      bvar-db-term->bvar-extension-p)))))



(defund add-term-bvar-unique (x bvar-db)
  (declare (xargs :stobjs bvar-db))
  (let ((look (get-term->bvar x bvar-db)))
    (if look
        (mv look bvar-db)
      (b* ((next (next-bvar bvar-db))
           (bvar-db (add-term-bvar x bvar-db)))
        (mv next bvar-db)))))

(defthm bvar-db-extension-p-of-add-term-bvar-unique
  (bvar-db-extension-p (mv-nth 1 (add-term-bvar-unique x bvar-db)) bvar-db)
  :hints(("Goal" :in-theory (enable add-term-bvar-unique))))

(defthm natp-bvar-of-add-term-bvar-unique
  (natp (mv-nth 0 (add-term-bvar-unique x bvar-db)))
  :hints(("Goal" :in-theory (enable add-term-bvar-unique)))
  :rule-classes :type-prescription)

(defthm add-term-bvar-unique-bvar-upper-bound
  (b* (((mv bvar new-bvar-db) (add-term-bvar-unique x bvar-db)))
    (< bvar (next-bvar$a new-bvar-db)))
  :hints(("Goal" :in-theory (enable add-term-bvar-unique)))
  :rule-classes (:rewrite :linear))

(defthm add-term-bvar-unique-bvar-lower-bound
  (b* (((mv bvar ?new-bvar-db) (add-term-bvar-unique x bvar-db)))
    (<= (base-bvar$a bvar-db) bvar))
  :hints(("Goal" :in-theory (enable add-term-bvar-unique)))
  :rule-classes (:rewrite :linear))

(defthm get-bvar->term-of-add-term-bvar-unique
  (b* (((mv bvar new-bvar-db) (add-term-bvar-unique x bvar-db)))
    (equal (get-bvar->term$a v new-bvar-db)
           (if (equal (nfix v) (nfix bvar))
               x
             (get-bvar->term$a v bvar-db))))
  :hints(("Goal" :in-theory (e/d (add-term-bvar-unique)
                                 (get-bvar->term$a-of-get-term->bvar))
          :use ((:instance get-bvar->term$a-of-get-term->bvar
                 (bvar-db$a bvar-db))))))

(defsection get-term->equivs

  (defund get-term->equivs (x bvar-db)
    (declare (xargs :stobjs bvar-db))
    (cdr (hons-get x (term-equivs bvar-db))))

  (local (in-theory (enable get-term->equivs)))

  (defthm bvar-listp-get-term->equivs
    (bvar-listp$a (get-term->equivs x bvar-db) bvar-db)
    :hints(("Goal" :in-theory (enable get-term->equivs)))))


(defsection add-term-equiv
  (defund add-term-equiv (x n bvar-db)
    (declare (xargs :guard (and (integerp n)
                                (<= (base-bvar bvar-db) n)
                                (< n (next-bvar bvar-db)))
                    :stobjs bvar-db))
    (update-term-equivs (hons-acons x
                                    (cons n (get-term->equivs x bvar-db))
                                    (term-equivs bvar-db))
                        bvar-db))

  (local (in-theory (enable add-term-equiv)))

  (defthm bvar-db-extension-p-of-add-term-equiv
    (bvar-db-extension-p (add-term-equiv x n bvar-db) bvar-db)
    :hints(("Goal" :in-theory (enable bvar-db-extension-p
                                      bvar-db-bvar->term-extension-p
                                      bvar-db-term->bvar-extension-p))))

  ;; implied by bvar-db-extension-p-of-add-term-equiv
  ;; (defthm base-bvar-of-add-term-equiv
  ;;   (equal (base-bvar$a (add-term-equiv x n bvar-db))
  ;;          (base-bvar$a bvar-db)))

  (defthm next-bvar-of-add-term-equiv
    (equal (next-bvar$a (add-term-equiv x n bvar-db))
           (next-bvar$a bvar-db)))

  (defthm get-term->bvar-of-add-term-equiv
    (equal (get-term->bvar$a y (add-term-equiv x n bvar-db))
           (get-term->bvar$a y bvar-db)))

  (defthm get-bvar->term-of-add-term-equiv
    (equal (get-bvar->term$a y (add-term-equiv x n bvar-db))
           (get-bvar->term$a y bvar-db))))



(defun bvar-db-debug-aux (n bvar-db)
  (declare (xargs :stobjs bvar-db
                  :guard (and (integerp n)
                              (<= (base-bvar bvar-db) n)
                              (<= n (next-bvar bvar-db)))
                  :measure (nfix (- (next-bvar bvar-db) (ifix n)))))
  (if (mbe :logic (zp (- (next-bvar bvar-db) (ifix n)))
           :exec (eql (next-bvar bvar-db) n))
      nil
    (cons (cons n (get-bvar->term n bvar-db))
          (bvar-db-debug-aux (1+ (lifix n)) bvar-db))))

(defun bvar-db-debug (bvar-db)
  (declare (xargs :stobjs bvar-db))
  (bvar-db-debug-aux (base-bvar bvar-db) bvar-db))


(acl2::set-prev-stobjs-correspondence add-term-bvar$a
                                      :stobjs-out (bvar-db)
                                      :formals (x bvar-db))

(acl2::set-prev-stobjs-correspondence update-term-equivs$a
                                      :stobjs-out (bvar-db)
                                      :formals (x bvar-db))
