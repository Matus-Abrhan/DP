
let lend_book (book_id : int) (loan_count : int ref) : unit =
  loan_count := !loan_count + 1;
  print_endline ("Book " ^ string_of_int book_id ^ " was lent for the " ^ string_of_int !loan_count ^ " time.")

let return_book (book_id : int) : unit = 
  print_endline ("Book " ^ string_of_int book_id ^ " was returned")

let interact_with_book (interactions_with_book : int ref) : unit =
  interactions_with_book := !interactions_with_book + 1

let print_number_interactions_with_book (book_id : int) (interactions_with_book : int) : unit =
  print_endline ("Interacted with book " ^ string_of_int book_id ^ " " ^ string_of_int interactions_with_book ^ " times.")