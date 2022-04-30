#lang scheme
; addpairs.scm
; Solomon Himelbloom
; 2022-04-21
;
; For CS F331 / CSCE A331 Spring 2022
; Programming in Scheme

; addpairs
(define (addpairs . args)
    (cond
        ((null? args) args)
        ((null? (cdr args)) args)
        (else (cons(+ (car args) (cadr args)) (apply addpairs (cddr args))))
    )
)
