async function handler(event) {
  const host = event.request.headers.host.value;
  const uri = event.request.uri;
    
  if(uri.includes("hg38/")) {
    const new_url = "https://legacy." + host + uri;
    const response = {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: { "location": { "value": new_url } } 
    };
    return response;
  }
  return event.request;
}
