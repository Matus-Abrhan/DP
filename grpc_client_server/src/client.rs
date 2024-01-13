use std::fs::{self, File};
use std::io::{Seek, SeekFrom, Read};
use log::debug;
use clap::Parser;
use sha256;

pub mod mon;
use mon::monitor_client::MonitorClient;
use mon::{Log, Client};

extern crate notify;
use notify::{Watcher, RecursiveMode, watcher, DebouncedEvent};
use std::sync::mpsc::channel;
use std::time::Duration;

#[derive(Debug, Parser)]
struct Options {
    #[clap(subcommand)]
    command: Command,
}

#[derive(Debug, Parser)]
enum Command {
   //Register(RegisterOptions),
   //SubmitLog(LogOptions),
   SetId(RegisterOptions),
}

#[derive(Debug, Parser)]
struct RegisterOptions {
   id: String,
}

async fn register(opts: RegisterOptions) -> Result<(), Box<dyn std::error::Error>> {
   let mut client = MonitorClient::connect("http://127.0.0.1:9001").await?;


   let request = tonic::Request::new(Client{ id: opts.id });
   let response = client.register(request).await?;
   //assert_eq!(response.into_inner().status, "success");
   debug!("{:?}", response.into_inner());
   
   return Ok(());
}

#[derive(Debug, Parser)]
struct LogOptions {
   id: String,
   data: String,
}

async fn submit_log(opts: LogOptions) -> Result<(), Box<dyn std::error::Error>> {
   let mut client = MonitorClient::connect("http://127.0.0.1:9001").await?;

   
   let request = tonic::Request::new(Log{ id: opts.id, data: opts.data });
   let response = client.submit_log(request).await?;

   //assert_eq!(response.into_inner().status, "success");
   debug!("{:?}", response.into_inner());

   return Ok(());
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
   env_logger::init();
   /*let opts = Options::parse();
   use Command::*;
   match opts.command {
       Register(opts) => register(opts).await?,
       SubmitLog(opts) => submit_log(opts).await?
   };
   return Ok(());*/
   
   let path = "logs.txt";
   let opts = Options::parse();
   let id = sha256::digest(match opts.command {
      Command::SetId(opts) => opts.id
   });
   let (tx, rx) = channel();
   let mut watcher = watcher(tx, Duration::from_millis(100)).unwrap();
   watcher.watch(path, RecursiveMode::NonRecursive).unwrap();

   let mut contents = fs::read_to_string(path).unwrap();
   let mut pos = contents.len() as u64;
   loop {
       match rx.recv() {
            Ok(DebouncedEvent::Write(_)) => {
                contents.clear();
                {
                let mut f = File::open(&path).unwrap();
                f.seek(SeekFrom::Start(pos)).unwrap();
                f.read_to_string(&mut contents).unwrap();
                pos = f.metadata().unwrap().len();
                }
                debug!("entry: \n{}", contents);
                submit_log(LogOptions{ id: id.to_owned(), data: contents.clone()}).await?;
            }
            Ok(_) => {}
            Err(err) => {
                eprintln!("Error: {:?}", err);
                std::process::exit(1);
            }
       }
   }
}
