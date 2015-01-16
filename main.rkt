#lang racket

(require mosquitto/api)

(void (mosquitto_lib_init))

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
    
    ; Wills
    
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
))