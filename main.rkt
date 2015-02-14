#lang racket/base

(require (for-syntax racket/base)
         racket/class
         (except-in mosquitto/api message message? message-mid message-topic message-payload message-qos message-retain)
         (prefix-in api/ mosquitto/api))
(provide mosquitto%
         mosquitto-version
         (struct-out message))

(void (mosquitto_lib_init))

(define-syntax (wrap-callback stx)
  (syntax-case stx ()
    [(_ cb args)
     (with-syntax ([arglist
                    (datum->syntax stx
                                   (append '(mosq udata) (syntax->datum #'args)))]
                   [call
                    (datum->syntax stx
                                   (cons (syntax->datum #'cb) (syntax->datum #'args)))])
       #`(if cb
             (lambda arglist call)
             #f))]))

(struct message (mid topic payload qos retain))
(define (transform-message msg)
  (message
   (api/message-mid msg)
   (api/message-topic msg)
   (api/message-copy-payload msg)
   (api/message-qos msg)
   (api/message-retain msg)))

; Public API
(define (mosquitto-version)
  (let-values ([(major minor revision version) (mosquitto_lib_version)])
    (values major minor revision)))

(define mosquitto%
  (class object%
    (init [id #f] [clean_session #t])
    (super-new)

    ; Initialisation
    (define client (mosquitto_new id clean_session #f))

    (define/public (reinitialise [id #f] #:clean_session [clean_session #t])
      (mosquitto_reinitialise client id clean_session #f))

    ; Authenticaion and encryption
    (define/public (set-username-password! username password)
      (mosquitto_username_pw_set client username password))

    (define/public (set-tls! cafile capath [certfile #f] [keyfile #f] #:callback [pw_callback #f])
      (define cb
        (if pw_callback
            (lambda (buf size rwflag udata) (pw_callback buf size rwflag))
            #f))
      (mosquitto_tls_set client cafile capath certfile keyfile cb))

    (define/public (set-tls-options! [requirements 'SSL_VERIFY_PEER] [tls_version #f] [ciphers #f])
      (define req
        (case requirements
          [('SSL_VERIFY_NONE) 0]
          [('SSL_VERIFY_PEER) 1]
          [else (error "Unknown peer requirements " requirements)]))
      (mosquitto_tls_opts_set client req tls_version ciphers))

    (define/public (set-tls-insecure! insecure)
      (mosquitto_tls_insecure_set client insecure))

    (define/public (set-tls-psk! psk identity [ciphers #f])
      (mosquitto_tls_psk_set client psk identity ciphers))

    ; Wills
    (define/public (set-will! topic payload [qos 0] [retain #f])
      (mosquitto_will_set client topic (bytes-length payload) payload qos retain))

    (define/public (clear-will!)
      (mosquitto_will_clear client))

    ; Connect/disconnect
    (define/public (connect host [port 1883] [keepalive 60] #:bind_address [bind_address #f])
      (if bind_address
          (mosquitto_connect_bind client host port keepalive bind_address)
          (mosquitto_connect client host port keepalive)))

    (define/public (connect-async host [port 1883] [keepalive 60] #:bind_address [bind_address #f])
      (if bind_address
          (mosquitto_connect_bind_async client host port keepalive bind_address)
          (mosquitto_connect_async client host port keepalive)))

    (define/public (reconnect)
      (mosquitto_reconnect client))

    (define/public (reconnect-async)
      (mosquitto_reconnect_async client))

    (define/public (disconnect)
      (mosquitto_disconnect client))

    ; Publish
    (define/public (publish topic payload [qos 0] [retain #f])
      (mosquitto_publish client topic (bytes-length payload) payload qos retain))

    ; Subscribe/unsubscribe
    (define/public (subscribe topic [qos 0])
      (mosquitto_subscribe client topic qos))

    (define/public (unsubscribe topic)
      (mosquitto_unsubscribe client topic))

    ; Network loop
    (define/public (loop [timeout -1])
      (mosquitto_loop client timeout 1))

    (define/public (loop-read)
      (mosquitto_loop_read client 1))

    (define/public (loop-write)
      (mosquitto_loop_write client 1))

    (define/public (loop-forever [timeout -1])
      (mosquitto_loop_forever client timeout 1))

    (define/public (socket)
      (mosquitto_socket client))

    (define/public (want-write)
      (mosquitto_want_write client))

    (define/public (loop-start)
      (mosquitto_loop_start client))

    (define/public (loop-stop)
      (mosquitto_loop_stop client #f))

    ; Misc client functions
    (define/public (set-max-inflight-messages! max)
      (mosquitto_max_inflight_messages_set client max))

    (define/public (set-message-retry! retry)
      (mosquitto_message_retry_set client retry))

    (define/public (set-reconnect-delay! delay max-delay exponential)
      (mosquitto_reconnect_delay_set client delay max-delay exponential))

    ; Callbacks
    (define connect-callback (box #f))
    (define/public (set-connect-callback! callback)
      (define cb (wrap-callback callback (retval)))
      (set-box! connect-callback cb)
      (mosquitto_connect_callback_set client cb))

    (define disconnect-callback (box #f))
    (define/public (set-disconnect-callback! callback)
      (define cb (wrap-callback callback (retval)))
      (set-box! disconnect-callback cb)
      (mosquitto_disconnect_callback_set client cb))

    (define publish-callback (box #f))
    (define/public (set-publish-callback! callback)
      (define cb (wrap-callback callback (mid)))
      (set-box! publish-callback cb)
      (mosquitto_publish_callback_set client cb))

    (define message-callback (box #f))
    (define/public (set-message-callback! callback)
      (let* ((cb (lambda (msg) (callback (transform-message msg))))
             (cb (wrap-callback cb (message))))
        (set-box! message-callback cb)
        (mosquitto_message_callback_set client cb)))

    (define subscribe-callback (box #f))
    (define/public (set-subscribe-callback! callback)
      (define cb (wrap-callback callback (mid qos_count granted_qos)))
      (set-box! subscribe-callback cb)
      (mosquitto_subscribe_callback_set client cb))

    (define unsubscribe-callback (box #f))
    (define/public (set-unsubscribe-callback! callback)
      (define cb (wrap-callback callback (mid)))
      (set-box! unsubscribe-callback cb)
      (mosquitto_unsubscribe_callback_set client cb))

    (define log-callback (box #f))
    (define/public (set-log-callback! callback)
      (define cb (wrap-callback callback (level string)))
      (set-box! log-callback cb)
      (mosquitto_log_callback_set client cb))))
