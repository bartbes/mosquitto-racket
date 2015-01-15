#lang racket

(require ffi/unsafe
         ffi/unsafe/define
         ffi/unsafe/alloc)

(define-ffi-definer define-mosquitto (ffi-lib "libmosquitto"))

; Global library function
(define-mosquitto mosquitto_lib_version (_fun
                                         (major : (_ptr o _int))
                                         (minor : (_ptr o _int))
                                         (revision : (_ptr o _int))
                                         -> (version : _int)
                                         -> (values major minor revision version)))

(define-mosquitto mosquitto_lib_init (_fun -> _int))
(define-mosquitto mosquitto_lib_cleanup (_fun -> _int))

; Client functions
;; Types
(define _mosquitto (_cpointer 'mosquitto))

(define _mid (_cpointer/null _int))
(define _userdata (_cpointer/null _void))

(define-cstruct _message ([mid _int]
                          [topic _string]
                          [payload _bytes]
                          [payloadlen _int]
                          [qos _int]
                          [retain _bool]))

(define _pw_callback (_fun _string _int _int _userdata -> _int))
(define _connect_callback (_fun _mosquitto _userdata _int -> _void))
(define _disconnect_callback (_fun _mosquitto _userdata _int -> _void))
(define _publish_callback (_fun _mosquitto _userdata _int -> _void))
(define _message_callback (_fun _mosquitto _userdata _message-pointer -> _void))
(define _subscribe_callback (_fun _mosquitto _userdata _int _int (_ptr i _int) -> _void))
(define _unsubscribe_callback (_fun _mosquitto _userdata _int -> _void))
(define _log_callback (_fun _mosquitto _userdata _int _string -> _void))

;; Client constructor/destructor
(define-mosquitto mosquitto_destroy (_fun _mosquitto -> _void)
  #:wrap (deallocator))
(define-mosquitto mosquitto_new (_fun _string _bool _userdata -> _mosquitto)
  #:wrap (allocator mosquitto_destroy))
(define-mosquitto mosquitto_reinitialise (_fun _mosquitto _string _bool _userdata -> _int))

;; Authentication and encryption
(define-mosquitto mosquitto_username_pw_set (_fun _mosquitto _string _string -> _int))
(define-mosquitto mosquitto_tls_set (_fun _mosquitto _path _path _path _path _pw_callback -> _int))
(define-mosquitto mosquitto_tls_opts_set (_fun _mosquitto _int _string _string -> _int))
(define-mosquitto mosquitto_tls_insecure_set (_fun _mosquitto _bool -> _int))
(define-mosquitto mosquitto_tls_psk_set (_fun _mosquitto _string _string _string -> _int))

;; Wills
(define-mosquitto mosquitto_will_set (_fun _mosquitto _string _int _bytes _int _bool -> _int))
(define-mosquitto mosquitto_will_clear (_fun _mosquitto -> _int))

;; Connect/disconnect
(define-mosquitto mosquitto_connect (_fun _mosquitto _string _int _int -> _int))
(define-mosquitto mosquitto_connect_bind (_fun _mosquitto _string _int _int _string -> _int))
(define-mosquitto mosquitto_connect_async (_fun _mosquitto _string _int _int -> _int))
(define-mosquitto mosquitto_connect_bind_async (_fun _mosquitto _string _int _int _string -> _int))
(define-mosquitto mosquitto_reconnect (_fun _mosquitto -> _int))
(define-mosquitto mosquitto_reconnect_async (_fun _mosquitto -> _int))
(define-mosquitto mosquitto_disconnect (_fun _mosquitto -> _int))

;; Publish
(define-mosquitto mosquitto_publish (_fun _mosquitto _mid _int _bytes _int _bool -> _int))

;; Subscribe/unsubscribe
(define-mosquitto mosquitto_subscribe (_fun _mosquitto _mid _string _int -> _int))
(define-mosquitto mosquitto_unsubscribe (_fun _mosquitto _mid _string -> _int))

;; Network loop
(define-mosquitto mosquitto_loop (_fun _mosquitto _int _int -> _int))
(define-mosquitto mosquitto_loop_read (_fun _mosquitto _int -> _int))
(define-mosquitto mosquitto_loop_write (_fun _mosquitto _int -> _int))
(define-mosquitto mosquitto_loop_misc (_fun _mosquitto -> _int))
(define-mosquitto mosquitto_loop_forever (_fun _mosquitto _int _int -> _int))
(define-mosquitto mosquitto_socket (_fun _mosquitto -> _int))
(define-mosquitto mosquitto_want_write (_fun _mosquitto -> _bool))

;; Threaded network loop
(define-mosquitto mosquitto_loop_start (_fun _mosquitto -> _int))
(define-mosquitto mosquitto_loop_stop (_fun _mosquitto _bool -> _int))

;; Misc client functions
(define-mosquitto mosquitto_max_inflight_messages_set (_fun _mosquitto _uint -> _int))
(define-mosquitto mosquitto_message_retry_set (_fun _mosquitto _uint -> _int))
(define-mosquitto mosquitto_reconnect_delay_set (_fun _mosquitto _uint _uint _bool -> _int))
(define-mosquitto mosquitto_user_data_set (_fun _mosquitto _userdata -> _int))

;; Callbacks

; Utility functions
(define-mosquitto mosquitto_connack_string (_fun _int -> _string))
(define-mosquitto mosquitto_message_free (_fun _message-pointer -> _int)
  #:wrap (deallocator))
(define-mosquitto mosquitto_message_copy (_fun _message-pointer _message-pointer -> _int)
  #:wrap (allocator mosquitto_message_free))
(define-mosquitto mosquitto_strerror (_fun _int -> _string))
;;; mosquitto_sub_topic_tokenise
;;; mosquitto_sub_topic_tokens_free
(define-mosquitto mosquitto_topic_matches_sub (_fun _string _string (result : (_ptr o _bool)) -> (error : _int) -> (values error result)))