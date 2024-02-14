//extern crate serde_derive;
//use serde_derive::Deserialize;

extern crate serde;
use serde::Deserialize;

#[derive(Deserialize, Default, Debug)]
pub struct Security {
    pub UserID: String,
}

#[derive(Deserialize, Default, Debug)]
pub struct Execution {
    pub ProcessID: String,
    pub ThreadID: String,
}

#[derive(Deserialize, Default, Debug)]
pub struct TimeCreated {
    pub SystemTime: String,
}

#[derive(Deserialize, Default, Debug)]
pub struct Provider {
    pub Name: String,
    pub Guid: String,
}

#[derive(Deserialize, Default, Debug)]
pub struct System {
    pub Provider: Provider,
    pub EventID: i32,
    pub Version: i32,
    pub Level: i32,
    pub Task: i32,
    pub Opcode: i32,
    pub Keywords: String,
    pub TimeCreated: TimeCreated,
    pub EventRecordID: i32,
    pub Correlation: String,
    pub Execution: Execution,
    pub Channel: String,
    pub Computer: String,
    pub Security: Security,
}


#[derive(Deserialize, Debug)]
pub struct Data {
    pub Name: String,
    #[serde(rename="$value")]
    pub value: String,
}

#[derive(Deserialize, Default, Debug)]
pub struct EventData {
    pub Data: Vec<Data>,
}

#[derive(Deserialize, Default, Debug, )]
pub struct SysmonEvent {
    pub System: System,
    pub EventData: EventData,
}
