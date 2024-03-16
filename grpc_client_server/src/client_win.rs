pub mod event_log;
pub mod query_list;
//use crate::event_log::subscriber::WinEventsSubscriber;
//use crate::event_log::sysmon_struct::SysmonEvent;
use crate::query_list::{EventFilter, Condition, QueryList, Comparison, Query, QueryItem};

use std::thread::sleep;
use std::time::{Duration, Instant};
use log::{debug, info};

pub mod mon;
use mon::monitor_client::MonitorClient;

fn transform(event: event_log::sysmon_struct::SysmonEvent) -> mon::SysmonEvent {
    let provider = mon::Provider{ 
        name: event.System.Provider.Name,
        guid: event.System.Provider.Guid };
    let event_id = event.System.EventID;
    let version = event.System.Version;
    let level = event.System.Level;
    let task = event.System.Task;
    let opcode = event.System.Opcode;
    let keyword = event.System.Keywords;
    let time_created = mon::TimeCreated{ system_time: event.System.TimeCreated.SystemTime };
    let event_record_id = event.System.EventRecordID;
    let correlation = event.System.Correlation;
    let execution = mon::Execution{ 
        process_id: event.System.Execution.ProcessID,
        thread_id: event.System.Execution.ThreadID };
    let channel = event.System.Channel;
    let computer = event.System.Computer;
    let security = mon::Security{ user_id: event.System.Security.UserID }; 

    let system = mon::System{ 
        provide: Some(provider), event_id, version, level,
        task, opcode, keyword, time_created: Some(time_created),
        event_record_id, correlation, execution: Some(execution),
        channel, computer, security: Some(security)};
    
    let mut event_data: Vec<mon::Data> = Vec::new();

    for d in event.EventData.Data {
        event_data.push(mon::Data{ name: d.Name, value: d.value })
    }
    
    let sysmon_event = mon::SysmonEvent{ system: Some(system), event_data: Some(mon::EventData{ data: event_data}) }; 
    return sysmon_event;
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    env_logger::builder().format_timestamp_micros().init();
    let id = "1".to_string();

    let conditions = vec![
        Condition::filter(EventFilter::level(1, Comparison::GreaterThanOrEqual)),
    ];
    let query = QueryList::new()
        .with_query(
            Query::new()
                .item(
                    QueryItem::selector("Microsoft-Windows-Sysmon/Operational".to_owned())
                        .system_conditions(Condition::or(conditions))
                        .build(),
                )
                .query(),
        )
        .build();

    let mut client = MonitorClient::connect("http://192.168.122.31:9001").await?;
    match event_log::subscriber::WinEventsSubscriber::get(query) {
        Ok(mut events) => {
            while let Some(event) = events.next() {
                // catch up to present
                //println!("Parsed: {:?}", event);
            }
            info!("Client started with ID: {:?}", id);
            loop {
                while let Some(event) = events.next() {
                    let start = Instant::now();
                    let parsed: event_log::sysmon_struct::SysmonEvent = event.into();
                    info!("{:?}", parsed);
                    let rpc: mon::SysmonEvent = transform(parsed);
                    debug!("sending request");
                    let request = tonic::Request::new(mon::Log{ id: id.clone(), event: Some(rpc) });
                    let response = client.submit_log(request).await?;
                    debug!("{:?}", response.into_inner());
                    info!("{:?}", start.elapsed())
                }
                sleep(Duration::from_millis(1000));
            }
        }
        Err(e) => println!("Error: {}", e),
    }
    Ok(())
}
