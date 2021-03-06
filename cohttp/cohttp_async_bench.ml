open Core.Std
open Async.Std
open Cohttp_async

let main n p =
  let server () =
    Server.(create (Tcp.on_port p)
              (fun ~body address request -> respond_with_string "Ok!"))
  in
  let get_n n =
    let rec inner = function
      | n when n <= 0 -> Deferred.unit
      | n ->
          Client.(get @@ Uri.of_string @@ "http://localhost:" ^ string_of_int p)
          >>= fun (_, body) ->
          let p = Body.to_pipe body in
          Pipe.close_read p;
          inner (pred n)
    in inner n
  in
  server () >>= fun server ->
  get_n n >>= fun () ->
  Shutdown.exit 0

let () =
  if Array.length Sys.argv < 2 then
    (
      Printf.printf "Usage: %s <nb_requests> [<port>]\n" Sys.argv.(0);
      Pervasives.exit 1
    );
  let port = if Array.length Sys.argv < 3
    then 8080 else int_of_string Sys.argv.(2) in
  don't_wait_for @@ main (int_of_string Sys.argv.(1)) port;
  never_returns @@ Scheduler.go ()
