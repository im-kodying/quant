mod configs;

use configs::account_const::{ACCT_NUM, ACCT_NUM_PAPER, HOST, HOST_PAPER, USE_PAPER};
use ibkr_client_portal::client::IBClientPortal;
use ibkr_client_portal::model::account::GetAccountSummaryRequest;
use ibkr_client_portal::retry_policies::ExponentialBackoff;

#[tokio::main]
async fn main() {
    println!("Trading Launching...");
    let account_num;
    let host;
    if USE_PAPER {
        account_num = ACCT_NUM_PAPER;
        host = HOST_PAPER;
    } else {
        account_num = ACCT_NUM;
        host = HOST;
    }
    let ib_cp_client = IBClientPortal::new(
        account_num.to_owned(),
        Default::default(),
        true,
        ExponentialBackoff::builder().build_with_max_retries(3),
    );
    let response_result = ib_cp_client
        .get_account_summary(GetAccountSummaryRequest {
            account_id: account_num.to_owned(),
        })
        .await;
    println!("{:?}", response_result);
}
