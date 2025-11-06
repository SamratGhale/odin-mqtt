package mqtt

import "core:sys/posix"

foreign import lib {
	"lib/libmqtt.a",
	"lib/libmqtt_pal.a",
}

pal_mutex_t       :: posix.pthread_mutex_t


@(link_prefix="mqtt_", default_calling_convention="c")
foreign lib{
	error_str                :: proc(error : Errors) -> cstring ---
	unpack_fixed_header      :: proc(response: ^response, buf: ^u8, bufsz: size_t)-> ssize_t---
	unpack_connack_response  :: proc(response: ^response, buf: ^u8)->ssize_t---
	unpack_publish_response  :: proc(response: ^response, buf: ^u8)->ssize_t---
	unpack_pubxxx_response   :: proc(response: ^response, buf: ^u8)->ssize_t---
	unpack_suback_response   :: proc(response: ^response, buf: ^u8)->ssize_t---
	unpack_unsuback_response :: proc(response: ^response, buf: ^u8)->ssize_t---
	unpack_response          :: proc(response: ^response, buf: ^u8, bufsz: size_t)->ssize_t---
	pack_fixed_header        :: proc(buf: ^u8, bufsz: size_t, fixed_header: ^fixed_header)->ssize_t---
	pack_connection_request  :: proc(buf: ^u8, bufsz: size_t, client_id: cstring, will_topic: cstring,
		will_message: rawptr, will_message_size: size_t, user_name: cstring,
		password: cstring, connect_flags: u8, keep_alive: u16,
		)->ssize_t---

	pack_publish_request :: proc(buf: ^u8, bufsz: size_t,
		topic_name: cstring,
		packet_id: u16,
		application_message: rawptr,
		application_message_size: size_t,
		publish_flags: u8
		)->ssize_t---

	pack_pubxxx_request :: proc(buf: u8, bufsz: size_t,
		control_type: ControlPacketType,
		packet_id: u16,
		)->ssize_t---

	pack_subscribe_request   :: proc(buf: ^u8, bufsz: size_t, packet_id: u16, )->ssize_t---
	pack_unsubscribe_request :: proc(buf: ^u8, bufsz: size_t, packet_id: u16, )->ssize_t---
	pack_ping_request        :: proc(buf: ^u8, bufsz: size_t,)->ssize_t---
	pack_disconnect          :: proc(buf: ^u8, bufsz: size_t,)->ssize_t---
	mq_init 	         :: proc(mq: ^message_queue, buf: ^u8, bufsz: i32,)---
	mq_clean                 :: proc(mq: ^message_queue,)---
	mq_register              :: proc(mq: ^message_queue, nbytes: i32)-> ^queued_message ---
	mq_find                  :: proc(mq: ^message_queue, control_type : ControlPacketType, packet_id: ^u16)-> ^queued_message ---
	sync                     :: proc(client: ^Client) -> Errors ---
	init                     :: proc(client: ^Client, sockfd: pal_socket_handle, 
		sendbuf: ^u8, sendbufsz: size_t,
		recvbuf: ^u8, recvbufsz: size_t,
		publish_response_callback : proc "c" (
			state: ^rawptr, publish: ^response_publish
			)
		)-> Errors---

	init_reconnect :: proc(client: ^Client, 
		reconnect_callback : proc(
			client: ^Client, state: ^rawptr),
		reconnect_state: rawptr,
		publish_response_callback : proc(
			state: ^rawptr, publish: ^response_publish)
		)---

	reinit :: proc(client: ^Client, sockfd: pal_socket_handle, 
		sendbuf: ^u8, sendbufsz: i32,
		recvbuf: ^u8, recvbufsz: i32,
		)---

	connect :: proc(client: ^Client,
		client_id: cstring,
		will_topic: cstring,
		will_message: rawptr ,
		will_message_size: i32,
		user_name: cstring,
		password: cstring,
		connect_flags: u8,
		keep_alive: u16)-> Errors ---

	publish :: proc(client: ^Client,
		topic_name: cstring,
		application_message: rawptr,
		application_message_size: i32,
		publish_flags: u8)-> Errors ---

	subscribe   :: proc(client: ^Client, topic_name: cstring, max_qos_level: i32)->Errors ---
	unsubscribe :: proc(client: ^Client, topic_name: cstring, )->Errors ---
	ping        :: proc(client: ^Client, )->Errors ---
	disconnect  :: proc(client: ^Client, )->Errors ---
	reconnect   :: proc(client: ^Client, )->Errors ---
}
