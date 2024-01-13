use tonic::transport::Server;

use server::RegisteredClients;
use mon::monitor_server::MonitorServer;

use env_logger;

pub mod server;
pub mod mon;

mod mon_proto {
   include!("mon.rs");
   pub(crate) const FILE_DESCRIPTOR_SET: &[u8] =
      tonic::include_file_descriptor_set!("store_descriptor");
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
   env_logger::init();

   let addr = "127.0.0.1:9001".parse()?;
   let clients = RegisteredClients::default();

   let reflection_service = tonic_reflection::server::Builder::configure()
           .register_encoded_file_descriptor_set(mon_proto::FILE_DESCRIPTOR_SET)
           .build()
           .unwrap();

   Server::builder()
           .add_service(MonitorServer::new(clients))
           .add_service(reflection_service)
           .serve(addr)
           .await?;

   Ok(())
}
