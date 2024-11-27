package mqtt

import "core:c"
import "core:c/libc"

/*
    TODO: Fix for linux
*/
import "core:sys/windows"

mqtt_pal_time_t :: libc.time_t
mqtt_pal_socket_handle :: i64
mqtt_pal_mutex_t :: windows.CRITICAL_SECTION

foreign import lib {
  "lib/mqtt.lib",
  "lib/mqtt_pal.lib",
}

ssize_t :: libc.ssize_t
size_t  :: libc.size_t

MQTTControlPacketType :: enum u32 {
    CONNECT=1,
    CONNACK=2,
    PUBLISH=3,
    PUBACK=4,
    PUBREC=5,
    PUBREL=6,
    PUBCOMP=7,
    SUBSCRIBE=8,
    SUBACK=9,
    UNSUBSCRIBE=10,
    UNSUBACK=11,
    PINGREQ=12,
    PINGRESP=13,
    DISCONNECT=14
};


mqtt_fixed_header :: bit_field u32 {
    /** The type of packet. */
    control_type: MQTTControlPacketType | 4,

    /** The packets control flags.*/
    control_flags : u32 | 4,

    /** The remaining size of the packet in bytes (i.e. the size of variable header and payload).*/
    remaining_length: u32 | 8,
};

MQTT_PROTOCOL_LEVEL :: 0x04


MQTTErrors :: enum i32{
    UNKNOWN = c.INT32_MIN,
    NULLPTR,                      
    CONTROL_FORBIDDEN_TYPE,       
    CONTROL_INVALID_FLAGS,        
    CONTROL_WRONG_TYPE,           
    CONNECT_CLIENT_ID_REFUSED,    
    CONNECT_NULL_WILL_MESSAGE,    
    CONNECT_FORBIDDEN_WILL_QOS,   
    CONNACK_FORBIDDEN_FLAGS,      
    CONNACK_FORBIDDEN_CODE,       
    PUBLISH_FORBIDDEN_QOS,        
    SUBSCRIBE_TOO_MANY_TOPICS,    
    MALFORMED_RESPONSE,           
    UNSUBSCRIBE_TOO_MANY_TOPICS,  
    RESPONSE_INVALID_CONTROL_TYPE,
    CONNECT_NOT_CALLED,           
    SEND_BUFFER_IS_FULL,          
    SOCKET_ERROR,                 
    MALFORMED_REQUEST,            
    RECV_BUFFER_TOO_SMALL,        
    ACK_OF_UNKNOWN,               
    NOT_IMPLEMENTED,              
    CONNECTION_REFUSED,           
    SUBSCRIBE_FAILED,             
    CONNECTION_CLOSED,            
    INITIAL_RECONNECT,            
    INVALID_REMAINING_LENGTH,     
    CLEAN_SESSION_IS_REQUIRED,    
    RECONNECT_FAILED,             
    RECONNECTING,
    OK = 1,
}


MQTTConnackReturnCode :: enum u8{
    ACCEPTED = 0,
    REFUSED_PROTOCOL_VERSION = 1,
    REFUSED_IDENTIFIER_REJECTED = 2,
    REFUSED_SERVER_UNAVAILABLE = 3,
    REFUSED_BAD_USER_NAME_OR_PASSWORD = 4,
    REFUSED_NOT_AUTHORIZED = 5,
};

mqtt_response_connack :: struct #packed {
    /** 
     * @brief Allows client and broker to check if they have a consistent view about whether there is
     * already a stored session state.
    */
    session_present_flag : u8,

    /** 
     * @brief The return code of the connection request. 
     * 
     * @see MQTTConnackReturnCode
     */
    return_code: MQTTConnackReturnCode,
};




mqtt_response_publish :: struct {
    /** 
     * @brief The DUP flag. DUP flag is 0 if its the first attempt to send this publish packet. A DUP flag
     * of 1 means that this might be a re-delivery of the packet.
     */
    dup_flag : u8,

    /** 
     * @brief The quality of service level.
     * 
     * @see <a href="http://docs.oasis-open.org/mqtt/mqtt/v3.1.1/os/mqtt-v3.1.1-os.html#_Table_3.11_-">
     * MQTT v3.1.1: QoS Definitions
     * </a>
     */
    qos_level: u8,

    /** @brief The retain flag of this publish message. */
    retain_flag: u8,

    /** @brief Size of the topic name (number of characters). */
    topic_name_size: u16,

    /** 
     * @brief The topic name. 
     * @note topic_name is not null terminated. Therefore topic_name_size must be used to get the 
     *       string length.
     */
    topic_name: rawptr,

    /** @brief The publish message's packet ID. */
    packet_id: u16,

    /** @brief The publish message's application message.*/
    application_message: rawptr,

    /** @brief The size of the application message in bytes. */
    application_message_size: size_t,
};

mqtt_response_pubrel :: struct {
    /** @brief The published messages packet ID. */
    packet_id : u16
};

MQTTSubackReturnCodes :: enum {
    SUCCESS_MAX_QOS_0 = 0,
    SUCCESS_MAX_QOS_1 = 1,
    SUCCESS_MAX_QOS_2 = 2,
    FAILURE           = 128
};

mqtt_response_suback :: struct{
    /** @brief The published messages packet ID. */
    packet_id : u16,

    /** 
     * Array of return codes corresponding to the requested subscribe topics.
     * 
     * @see MQTTSubackReturnCodes
     */
    return_codes : ^u8,

    /** The number of return codes. */
    num_return_codes: size_t,
};

mqtt_response_unsuback  :: struct{
    /** @brief The published messages packet ID. */
    packet_id: u16,
};
mqtt_response_puback :: struct{
    /** @brief The published messages packet ID. */
    packet_id: u16,
};
mqtt_response_pubrec:: struct{
    /** @brief The published messages packet ID. */
    packet_id: u16,
};

mqtt_response_pubcomp:: struct{
    /** @brief The published messages packet ID. */
    packet_id: u16,
};


mqtt_response_pingresp  :: struct{
  dummy: i32,
};




mqtt_response :: struct{
    /** @brief The mqtt_fixed_header of the deserialized packet. */
    fixed_header : mqtt_fixed_header,

    /**
     * @brief A union of the possible responses from the broker.
     * 
     * @note The fixed_header contains the control type. This control type corresponds to the
     *       member of this union that should be accessed. For example if 
     *       fixed_header#control_type == \c MQTT_CONTROL_PUBLISH then 
     *       decoded#publish should be accessed.
     */
    decoded : struct #raw_union{
        connack: mqtt_response_connack,
        publish: mqtt_response_publish,
        puback : mqtt_response_puback,
        pubrec: mqtt_response_pubrec,
        pubrel: mqtt_response_pubrel,
        pubcomp: mqtt_response_pubcomp,
        suback: mqtt_response_suback,
        unsuback: mqtt_response_unsuback,
        pingresp: mqtt_response_pingresp 
    }
};

MQTTConnectFlags :: enum u8{
    RESERVED = 1,
    CLEAN_SESSION = 2,
    WILL_FLAG = 4,
    WILL_QOS_0 = (0 & 0x03) << 3,
    WILL_QOS_1 = (1 & 0x03) << 3,
    WILL_QOS_2 = (2 & 0x03) << 3,
    WILL_RETAIN = 32,
    PASSWORD = 64,
    USER_NAME = 128
};


MQTTPublishFlags :: enum u8{
    MQTT_PUBLISH_DUP = 8,
    MQTT_PUBLISH_QOS_0 = ((0 << 1) & 0x06),
    MQTT_PUBLISH_QOS_1 = ((1 << 1) & 0x06),
    MQTT_PUBLISH_QOS_2 = ((2 << 1) & 0x06),
    MQTT_PUBLISH_QOS_MASK = ((3 << 1) & 0x06),
    MQTT_PUBLISH_RETAIN = 0x01
};

MQTT_SUBSCRIBE_REQUEST_MAX_NUM_TOPICS :: 8
MQTT_UNSUBSCRIBE_REQUEST_MAX_NUM_TOPICS :: 8

MQTTQueuedMessageState :: enum {
    MQTT_QUEUED_UNSENT,
    MQTT_QUEUED_AWAITING_ACK,
    MQTT_QUEUED_COMPLETE
};




mqtt_queued_message :: struct{
    /** @brief A pointer to the start of the message. */
    start: ^u8,

    /** @brief The number of bytes in the message. */
    size: size_t,


    /** @brief The state of the message. */
    state: MQTTQueuedMessageState,

    /** 
     * @brief The time at which the message was sent..
     * 
     * @note A timeout will only occur if the message is in
     *       the MQTT_QUEUED_AWAITING_ACK \c state.
     */
    time_sent: mqtt_pal_time_t,

    /**
     * @brief The control type of the message.
     */
    control_type: MQTTControlPacketType,

    /** 
     * @brief The packet id of the message.
     * 
     * @note This field is only used if the associate \c control_type has a 
     *       \c packet_id field.
     */
    packet_id: u16,
};


mqtt_message_queue :: struct {
    /** 
     * @brief The start of the message queue's memory block. 
     * 
     * @warning This member should \em not be manually changed.
     */
    mem_start: rawptr,

    /** @brief The end of the message queue's memory block. */
    mem_end: rawptr,

    /**
     * @brief A pointer to the position in the buffer you can pack bytes at.
     * 
     * @note Immediately after packing bytes at \c curr you \em must call
     *       mqtt_mq_register.
     */
    curr: ^u8,

    /**
     * @brief The number of bytes that can be written to \c curr.
     * 
     * @note curr_sz will decrease by more than the number of bytes you write to 
     *       \c curr. This is because the mqtt_queued_message structs share the 
     *       same memory (and thus, a mqtt_queued_message must be allocated in 
     *       the message queue's memory whenever a new message is registered).  
     */
    curr_sz: size_t,
    
    /**
     * @brief The tail of the array of mqtt_queued_messages's.
     * 
     * @note This member should not be used manually.
     */
    queue_tail: ^mqtt_queued_message,
};


mqtt_client :: struct {
    /** @brief The socket connecting to the MQTT broker. */
    socketfd: mqtt_pal_socket_handle,

    /** @brief The LFSR state used to generate packet ID's. */
    pid_lfsr: u16,

    /** @brief The keep-alive time in seconds. */
    keep_alive: u16,

    /** 
     * @brief A counter counting pings that have been sent to keep the connection alive. 
     * @see keep_alive
     */
     number_of_keep_alives:     i32,

    /**
     * @brief The current sent offset.
     *
     * This is used to allow partial send commands.
     */
    send_offset: size_t,

    /** 
     * @brief The timestamp of the last message sent to the buffer.
     * 
     * This is used to detect the need for keep-alive pings.
     * 
     * @see keep_alive
    */
    time_of_last_send: mqtt_pal_time_t,

    /** 
     * @brief The error state of the client. 
     * 
     * error should be MQTT_OK for the entirety of the connection.
     * 
     * @note The error state will be MQTT_ERROR_CONNECT_NOT_CALLED until
     *       you call mqtt_connect.
     */
    error: MQTTErrors,

    /** 
     * @brief The timeout period in seconds.
     * 
     * If the broker doesn't return an ACK within response_timeout seconds a timeout
     * will occur and the message will be retransmitted. 
     * 
     * @note The default value is 30 [seconds] but you can change it at any time.
     */
    response_timeout: i32,

    /** @brief A counter counting the number of timeouts that have occurred. */
    number_of_timeouts: i32,

    /**
     * @brief Approximately much time it has typically taken to receive responses from the 
     *        broker.
     * 
     * @note This is tracked using a exponential-averaging.
     */
    typical_response_time: f32,

    /**
     * @brief The callback that is called whenever a publish is received from the broker.
     * 
     * Any topics that you have subscribed to will be returned from the broker as 
     * mqtt_response_publish messages. All the publishes received from the broker will 
     * be passed to this function.
     * 
     * @note A pointer to publish_response_callback_state is always passed to the callback.
     *       Use publish_response_callback_state to keep track of any state information you 
     *       need.
     */
     publish_response_callback : proc "c" (state: ^rawptr, publish: ^mqtt_response_publish),

    /**
     * @brief A pointer to any publish_response_callback state information you need.
     * 
     * @note A pointer to this pointer will always be publish_response_callback upon 
     *       receiving a publish message from the broker.
     */
    publish_response_callback_state: rawptr,

    /**
     * @brief A user-specified callback, triggered on each \ref mqtt_sync, allowing
     *        the user to perform state inspections (and custom socket error detection)
     *        on the client.
     * 
     * This callback is triggered on each call to \ref mqtt_sync. If it returns MQTT_OK
     * then \ref mqtt_sync will continue normally (performing reads and writes). If it
     * returns an error then \ref mqtt_sync will not call reads and writes.
     * 
     * This callback can be used to perform custom error detection, namely platform
     * specific socket error detection, and force the client into an error state.
     * 
     * This member is always initialized to NULL but it can be manually set at any 
     * time.
     */
     inspector_callback : proc(client: ^mqtt_client) -> MQTTErrors,

    /**
     * @brief A callback that is called whenever the client is in an error state.
     * 
     * This callback is responsible for: application level error handling, closing
     * previous sockets, and reestabilishing the connection to the broker and 
     * session configurations (i.e. subscriptions).  
     */
     reconnect_callback : proc(client: ^mqtt_client, data: ^rawptr),

    /**
     * @brief A pointer to some state. A pointer to this member is passed to 
     *        \ref mqtt_client.reconnect_callback.
     */
    reconnect_state: rawptr,

    /**
     * @brief The buffer where ingress data is temporarily stored.
     */
    recv_buffer: struct {
        /** @brief The start of the receive buffer's memory. */
        mem_start: ^u8,
        /** @brief The size of the receive buffer's memory. */
        mem_size: size_t,

        /** @brief A pointer to the next writable location in the receive buffer. */
        curr: ^u8,

        /** @brief The number of bytes that are still writable at curr. */
        curr_sz: size_t,
    },

    /** 
     * @brief A variable passed to support thread-safety.
     * 
     * A pointer to this variable is passed to \c MQTT_PAL_MUTEX_LOCK, and
     * \c MQTT_PAL_MUTEX_UNLOCK.
     */
    mutex: mqtt_pal_mutex_t,

    /** @brief The sending message queue. */
    mq: mqtt_message_queue,
};

//mqtt pal

@(link_prefix="mqtt_", default_calling_convention="c")
foreign lib{
  error_str :: proc(error : MQTTErrors) -> cstring ---

  unpack_fixed_header :: proc(response: ^mqtt_response, buf: ^u8, bufsz: size_t)-> ssize_t---

  unpack_connack_response :: proc(response: ^mqtt_response, buf: ^u8)->ssize_t---

  unpack_publish_response :: proc(response: ^mqtt_response, buf: ^u8)->ssize_t---

  unpack_pubxxx_response :: proc(response: ^mqtt_response, buf: ^u8)->ssize_t---

  unpack_suback_response :: proc(response: ^mqtt_response, buf: ^u8)->ssize_t---

  unpack_unsuback_response :: proc(response: ^mqtt_response, buf: ^u8)->ssize_t---

  unpack_response :: proc(response: ^mqtt_response, buf: ^u8, bufsz: size_t)->ssize_t---

  pack_fixed_header:: proc(buf: ^u8, bufsz: size_t, fixed_header: ^mqtt_fixed_header)->ssize_t---

  pack_connection_request:: proc(buf: ^u8, bufsz: size_t, 
                                client_id: cstring,
                                will_topic: cstring,
                                will_message: rawptr,
                                will_message_size: size_t,
                                user_name: cstring,
                                password: cstring,
                                connect_flags: u8,
                                keep_alive: u16,
                                )->ssize_t---


  pack_publish_request :: proc(buf: ^u8, bufsz: size_t,
                                  topic_name: cstring,
                                  packet_id: u16,
                                  application_message: rawptr,
                                  application_message_size: size_t,
                                  publish_flags: u8
                                  )->ssize_t---

  pack_pubxxx_request :: proc(buf: u8, bufsz: size_t,
                                  control_type: MQTTControlPacketType,
                                  packet_id: u16,
                                  )->ssize_t---

  pack_subscribe_request :: proc(buf: ^u8, bufsz: size_t, packet_id: u16, )->ssize_t---

  pack_unsubscribe_request :: proc(buf: ^u8, bufsz: size_t, packet_id: u16, )->ssize_t---

  pack_ping_request :: proc(buf: ^u8, bufsz: size_t,)->ssize_t---

  pack_disconnect :: proc(buf: ^u8, bufsz: size_t,)->ssize_t---

  mq_init :: proc(mq: ^mqtt_message_queue, buf: ^u8, bufsz: i32,)---

  mq_clean :: proc(mq: ^mqtt_message_queue,)---

  mq_register :: proc(mq: ^mqtt_message_queue, nbytes: i32)-> ^mqtt_queued_message ---

  mq_find :: proc(mq: ^mqtt_message_queue, control_type : MQTTControlPacketType, packet_id: ^u16)-> ^mqtt_queued_message ---

  sync :: proc(client: ^mqtt_client) -> MQTTErrors ---

  init :: proc(client: ^mqtt_client, sockfd: mqtt_pal_socket_handle, 
                sendbuf: ^u8, sendbufsz: size_t,
                recvbuf: ^u8, recvbufsz: size_t,
                publish_response_callback : proc "c" (state: ^rawptr, publish: ^mqtt_response_publish)
    )-> MQTTErrors---

  init_reconnect :: proc(client: ^mqtt_client, 
                reconnect_callback : proc(client: ^mqtt_client, state: ^rawptr),
                reconnect_state: rawptr,
                publish_response_callback : proc(state: ^rawptr, publish: ^mqtt_response_publish)
    )---

  reinit :: proc(client: ^mqtt_client, sockfd: mqtt_pal_socket_handle, 
      sendbuf: ^u8, sendbufsz: i32,
      recvbuf: ^u8, recvbufsz: i32,
    )---

  connect :: proc(client: ^mqtt_client,
                             client_id: cstring,
                             will_topic: cstring,
                             will_message: rawptr ,
                             will_message_size: i32,
                             user_name: cstring,
                             password: cstring,
                             connect_flags: u8,
                             keep_alive: u16)-> MQTTErrors ---


  publish :: proc(client: ^mqtt_client,
                             topic_name: cstring,
                             application_message: rawptr,
                             application_message_size: i32,
                             publish_flags: u8)-> MQTTErrors ---


  subscribe :: proc(client: ^mqtt_client,
                               topic_name: cstring,
                               max_qos_level: i32)->MQTTErrors ---

  unsubscribe :: proc(client: ^mqtt_client,
                               topic_name: cstring,
                               )->MQTTErrors ---

  ping :: proc(client: ^mqtt_client, )->MQTTErrors ---

  disconnect :: proc(client: ^mqtt_client, )->MQTTErrors ---

  reconnect :: proc(client: ^mqtt_client, )->MQTTErrors ---

}


















