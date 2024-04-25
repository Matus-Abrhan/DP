
let lend_book (book_id : int) (loan_count : int ref) : unit = 
  loan_count := !loan_count + 1;
  print_endline ("Book " ^ (string_of_int book_id) ^ " was lent.")

let return_book (book_id : int) (loan_count : int ref) : unit = 
  print_endline ("Book " ^ (string_of_int book_id) ^ " was returned. Loan count is now : " ^ string_of_int(!loan_count))
  
