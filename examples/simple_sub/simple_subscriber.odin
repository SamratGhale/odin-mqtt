package simple_subscriber
import mqtt "../../"
import "core:time"
import "base:runtime"
import "core:strings"
import "core:net"
import "core:thread"
import "core:c/libc"
import "core:fmt"

sendbuf : [2048]u8
recvbuf : [2048]u8

publish_callback ::  proc "c"(unused: ^rawptr, published: ^mqtt.response_publish)
{
	context = runtime.default_context()
	fmt.println(cast(cstring)published.application_message)
}

main :: proc(){
	socket, err := net.dial_tcp_from_hostname_and_port_string("broker.hivemq.com:1883")

	if err != nil  do return


	client : mqtt.Client
	mqtt.init(&client, i64(socket), &sendbuf[0], len(sendbuf), &recvbuf[0], len(recvbuf), publish_callback)

	client_id : cstring
	connect_flags :  u8  = u8(mqtt.ConnectFlags.CLEAN_SESSION)

	mqtt.connect(&client, client_id, nil, nil, 0, nil, nil, connect_flags, 60)

	if client.error != .OK{
		fmt.println(client.error)
		return
	}
	refresh_thread := thread.create_and_start_with_data(rawptr(&client),client_refresher)

	error := mqtt.subscribe(&client, "testtopicsamrat", 0)
	fmt.println(error)

	fmt.println("Listening for messages")
	fmt.println("Press CTRL-D to exit")

	for libc.fgetc(libc.stdin)!= libc.EOF{

	}

	if client.socketfd != -1 do net.close(socket)
	thread.destroy(refresh_thread)
	mqtt.disconnect(&client)

}

client_refresher :: proc(client_raw: rawptr){
	for true{

		client := cast(^mqtt.Client)client_raw
		error := mqtt.sync(client)

		if error != .OK{
			fmt.println(error)
		}
		time.sleep(10000000)
	}
} 






