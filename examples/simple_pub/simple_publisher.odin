package simple_publisher
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

publish_callback ::  proc "c"(unused: ^rawptr, published: ^mqtt.mqtt_response_publish)
{
  context = runtime.default_context()
  fmt.println(published)
}

main :: proc(){
  using mqtt
  socket, err := net.dial_tcp_from_hostname_and_port_string("broker.hivemq.com:1883")
  net.set_blocking(socket, false)

  if err != nil  do return


  client : mqtt_client
  init(&client, i64(socket), &sendbuf[0], len(sendbuf), &recvbuf[0], len(recvbuf), publish_callback)

  client_id : cstring
  connect_flags :  u8  = u8(MQTTConnectFlags.CLEAN_SESSION)

  connect(&client, client_id, nil, nil, 0, nil, nil, connect_flags, 60)

  if(client.error != .OK){
    fmt.println(client.error)
  }
  refresh_thread := thread.create_and_start_with_data(rawptr(&client),client_refresher)

  fmt.println("Ready to begin publishing time")
  fmt.println("Press enter to publish the current time")
  fmt.println("Press CTRL-D (or any other key) to exit")

  for libc.fgetc(libc.stdin) == '\n'{
    msg : [255]u8
    curr_time := time.time_to_string_hms(time.now(), msg[:])
    publish(&client, "testtopicsamrat", rawptr(strings.unsafe_string_to_cstring(curr_time)) , i32(len(curr_time)), u8(MQTTPublishFlags.MQTT_PUBLISH_QOS_0))
    fmt.println("Published ", curr_time)

    if(client.error != .OK){
      fmt.println(client.error)
      if client.socketfd != -1 do net.close(socket)
      thread.destroy(refresh_thread)
      disconnect(&client)
    }

  }

  fmt.println("Disconnecting ")
  if client.socketfd != -1 do net.close(socket)
  thread.destroy(refresh_thread)
  disconnect(&client)

}

client_refresher :: proc(client_raw: rawptr){
  for true{

    client := cast(^mqtt.mqtt_client)client_raw
    mqtt.sync(client)
    //mqtt.ping(client)
    time.sleep(100000000)
  }
} 








