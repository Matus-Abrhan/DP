use futures::Stream;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::pin::Pin;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex};
use tokio_stream::wrappers::UnboundedReceiverStream;
use tonic::{Request, Response, Status};
use log::{debug, info};

use crate::mon::monitor_server::Monitor;
use crate::mon::{SysmonEvent, RegisterResponse, Client, SubmitLogResponse, Log};

#[derive(Debug)]
pub struct RegisteredClients {
    clients: Arc<Mutex<HashMap<String, SysmonEvent>>>,
}

impl Default for RegisteredClients {
    fn default() -> Self {
        RegisteredClients {
            clients: Arc::new(Mutex::new(HashMap::<String, SysmonEvent>::new())),
        }
    }
}

#[tonic::async_trait]
impl Monitor for RegisteredClients {
    async fn register(&self, request: Request<Client>) -> Result<Response<RegisterResponse>, Status> {
        let client = request.into_inner();
        debug!("{:?}", client);

        
        debug!("{:?}", self.clients);
        Ok(Response::new(RegisterResponse {
            status: "success".into(),
        }))
    }

    async fn submit_log(&self, request: Request<Log>) -> Result<Response<SubmitLogResponse>, Status> {
        let log = request.into_inner();
        
        {
            let mut map = self.clients.lock().await;
            map.entry(log.id).and_modify(|v| *v=log.event.as_ref().unwrap().clone()).or_insert(log.event.as_ref().unwrap().clone());
        }
        debug!("{:?}", log.event);

        Ok(Response::new(SubmitLogResponse {
            status: "success".into(),
        }))
    }
}
