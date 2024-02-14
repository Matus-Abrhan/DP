use std::fs::{self, File};
use std::io::{Seek, SeekFrom, Read};
use std::path::Path;
use log::{debug, warn, error};
use clap::Parser;
use evtx;
//use sha256;

pub mod mon;
use mon::monitor_client::MonitorClient;
use mon::{Log, Client};

extern crate notify;
use notify::{Watcher, RecommendedWatcher, RecursiveMode, EventKind};
use std::sync::mpsc::channel;

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

   //let request = tonic::Request::new(Log{ id: opts.id, event: opts.data });
   //let response = client.submit_log(request).await?;
   //debug!("{:?}", response.into_inner());

   return Ok(());
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
   env_logger::builder().format_timestamp_micros().init();
   let path = Path::new(r"Microsoft-Windows-Sysmon%4Operational.evtx");
   let opts = Options::parse();
   /*let id = sha256::digest(match opts.command {
      Command::SetId(opts) => opts.id
   });*/
   let id = match opts.command {
      Command::SetId(opts) => opts.id
   };
   let (tx, rx) = channel();
   let mut watcher = RecommendedWatcher::new(tx, notify::Config::default())?;
   watcher.watch(path, RecursiveMode::NonRecursive).unwrap();

   //let mut contents = fs::read_to_string(path).unwrap();
   let mut parser = evtx::EvtxParser::from_path(path).unwrap();
   for  record in parser.records() {
      match record {
         Ok(r) => {
            debug!("Record {}", r.event_record_id);
            submit_log(LogOptions { id: id.to_owned(), data: r.data.to_owned() }).await?;
         }
         Err(e) => eprintln!("{}", e),
      }
   }
   //let mut pos = contents.len() as u64;
   loop {
      match rx.recv().expect("Transmission failed") {
         Ok(event) => {
            match event.kind {
               /*EventKind::Modify(_) => { 
                  contents.clear();
                  {
                     let mut f = File::open(&path).unwrap();
                     f.seek(SeekFrom::Start(pos)).unwrap();
                     f.read_to_string(&mut contents).unwrap();
                     pos = f.metadata().unwrap().len();
                  }
                  debug!("read size: {}", contents.len());
                  submit_log(LogOptions { id: id.to_owned(), data: contents.to_owned() }).await?;
               }*/
               EventKind::Remove(_) => { 
                  warn!("TODO: should implement restart for remove event");
                  //watcher = RecommendedWatcher::new(tx, notify::Config::default())?;
                  watcher.watch(path, RecursiveMode::NonRecursive).unwrap();
               }
               _ => { debug!("{:?}", event.kind); }
            }
         }
         Err(err) => { error!("{:?}", err) }
      }
   }
}
