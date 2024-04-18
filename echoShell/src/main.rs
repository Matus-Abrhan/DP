use core::panic;
use std::{
    io::{self, Write},
    process::exit,
};

fn main() {
    println!("Starting echoShell");

    let prompt: &str = "prompt# ";
    let mut input: String = String::new();
    //let stdin = io::stdin();

    loop {
        print!("{}", &prompt);
        let _ = io::stdout().flush();
        match io::stdin().read_line(&mut input) {
            Ok(_n) => {
                if input.contains("exit") {
                    println!("Exiting");
                    exit(0);
                }
                println!("{}", input);
                input.clear();
            }
            Err(err) => {
                panic!("Error: {}", err);
            }
        };
    }
}
