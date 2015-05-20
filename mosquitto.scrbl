#lang scribble/doc

@(require scribble/manual
          (for-label racket/class)
          (for-label "main.rkt"))

@title{Mosquitto}
@author{@(author+email "Bart van Strien" "bartbes@gmail.com")}

@defmodule[mosquitto]
This package provides an FFI interface to @link["http://mosquitto.org/"]{libmosquitto}.
It attempts to mostly match its API, documented @link["http://mosquitto.org/api/files/mosquitto-h.html"]{here}.

@defclass[mosquitto% object% ()]{
  @; Inititalisation
  @defconstructor[([id string? #f] [clean_session boolean? #f])]
  @defmethod[(reinitialise [id string? #f] [#:clean_session clean_session boolean? #f]) mosquitto-returncode/c]
  
  @; Authentication and encryption
  @defmethod[(set-username-password! [username string?] [password string?]) mosquitto-returncode/c]
  @defmethod[(set-tls-client! [certfile string?] [keyfile string?] [#:callback pw_callback (-> buf size rwflag void) #f]) mosquitto-returncode/c]
  @defmethod[(set-tls-ca! [#:cafile cafile string? #f] [#:capath capath string? #f]) mosquitto-returncode/c]
  @defmethod[(set-tls-insecure! [insecure boolean?]) mosquitto-returncode/c]
  @defmethod[(set-tls-psk! [psk string?] [identity string?] [ciphers string? #f]) mosquitto-returncode/c]
  
  @; Wills
  @defmethod[(set-will! [topic string?] [payload string?] [qos (or/c 0 1 2) 0] [retain boolean? #f]) mosquitto-returncode/c]
  @defmethod[(clear-will!) mosquitto-returncode/c]
  
  @; Connect/disconnect
  @defmethod[(connect [host string?] [port exact-nonnegative-integer? 1883] [keepalive exact-nonnegative-integer? 60] [#:bind_address bind_address string? #f]) mosquitto-returncode/c]
  @defmethod[(connect-async [host string?] [port exact-nonnegative-integer? 1883] [keepalive exact-nonnegative-integer? 60] [#:bind_address bind_address string? #f]) mosquitto-returncode/c]
  @defmethod[(reconnect) mosquitto-returncode/c]
  @defmethod[(reconnect-async) mosquitto-returncode/c]
  @defmethod[(disconnect) mosquitto-returncode/c]

  @; Publish
  @defmethod[(publish [topic string?] [payload bytes?] [qos (or/c 0 1 2) 0] [return boolean? #f]) mosquitto-returncode/c]

  @; Subscribe/unsubscribe
  @defmethod[(subscribe [topic string?] [qos (or/c 0 1 2) 0]) mosquitto-returncode/c]
  @defmethod[(unsubscribe [topic string?]) mosquitto-returncode/c]
}
