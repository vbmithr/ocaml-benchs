open Lwt
open Cohttp_lwt_unix

let main n p =
  let server () =
    let open Server in
    let callback conn req body =
      respond_string ~status:`OK ~body:"Ok!" () in
    let conn_closed conn () = ()
    in
    create ~address:"localhost" ~port:8080 { callback; conn_closed; }
  in
  let get_n n =
    let rec inner = function
      | n when n <= 0 -> Lwt.return_unit
      | n ->
          Client.(get @@ Uri.of_string @@ "http://localhost:" ^ string_of_int p)
          >>= fun (_, body) ->
          Cohttp_lwt_body.drain_body body >>= fun () ->
          inner (pred n)
    in inner n
  in
  Lwt.async server;
  get_n n

let () =
  if Array.length Sys.argv < 2 then
    (
      Printf.printf "Usage: %s <nb_requests> [<port>]\n" Sys.argv.(0);
      Pervasives.exit 1
    );
  let port = if Array.length Sys.argv < 3
    then 8080 else int_of_string Sys.argv.(2) in
  Lwt_main.run @@ main (int_of_string Sys.argv.(1)) port;

