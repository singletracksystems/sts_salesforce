/**
 * Test Connection
 * User: sergiogarciamancha
 * Date: 01/07/2013
 * Time: 10:20
 */


$(function (){
    $('.testConnection').on('click',onTestConnection);
})

function onTestConnection ( eventObject ) {
    $('.testConnection').attr('disabled','disabled');
    $('#connResult').text('Connecting...');
    var data = {username: $('#salesforce_org_username').val(),
        password: $('#salesforce_org_password').val(),
        token: $('#salesforce_org_token').val(),
        client_id: $('#salesforce_org_client_id').val(),
        client_secret: $('#salesforce_org_client_secret').val(),
        sandbox: $('#salesforce_org_sandbox').val()};
    $.getJSON('http://'+window.location.host+'/testconnection',{salesforce_org :data}).done(onTestConnectionCallback).fail(onFail)
        .always(function(){$('.testConnection')
            .removeAttr('disabled')});
}

function onFail (jqXHR, textStatus, errorThrown) {
    alert('fail');
    $('#connResult').text(textStatus + ": " + errorThrown);
    alert('fail');
}

function onTestConnectionCallback ( data, textStatus, jqXHR) {
    $('#connResult').text(data.message);
}
