# Alerting


Connaisseur can send notifications on admission decisions to basically every REST
endpoint that accepts JSON payloads.

## Supported interfaces

Slack, Opsgenie, Keybase and Microsoft Teams have pre-configured payloads that are ready to use.
Additionally, there is a template matching the [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/1.12/index.html) in version 1.12.
However, you can use the existing payload templates as an example how to model your
own custom one.
It is also possible to configure multiple interfaces for receiving
alerts at the same time.

## Configuration options

Currently, Connaisseur supports alerting on either admittance of images, denial of images or both. These event categories can be configured independently of each other under the relevant category (i.e. `admitRequest` or `rejectRequest`):

| Key                                                        | Accepted values                                                               | Default           | Required           | Description                                                                                     |
|------------------------------------------------------------|-------------------------------------------------------------------------------|-------------------|--------------------|-------------------------------------------------------------------------------------------------|
| `alerting.clusterIdentifier`                               | string                                                                        | `"not specified"` | -                  | Cluster identifier used in alert payload to distinguish between alerts from different clusters. |
| `alerting.<category>.receivers.[].template`                | `opsgenie`, `slack`, `keybase`, `msteams`, `ecs-1-12-0` or custom<sup>*</sup> | -                 | :heavy_check_mark: | File in `helm/alert_payload_templates/` to be used as alert payload template.                   |
| `alerting.<category>.receivers.[].receiverUrl`             | string                                                                        | -                 | :heavy_check_mark: | URL of alert-receiving endpoint.                                                                |
| `alerting.<category>.receivers.[].priority`                | int                                                                           | `3`               | -                  | Priority of alert (to enable fitting Connaisseur alerts into alerts from other sources).        |
| `alerting.<category>.receivers.[].customHeaders`           | list[string]                                                                  | -                 | -                  | Additional headers required by alert-receiving endpoint.                                        |
| `alerting.<category>.receivers.[].payloadFields`           | subyaml                                                                       | -                 | -                  | Additional (`yaml`) key-value pairs to be appended to alert payload (as `json`).                |
| `alerting.<category>.receivers.[].failIfAlertSendingFails` | bool                                                                          | `false`           | -                  | Whether to make Connaisseur deny images if the corresponding alert cannot be successfully sent. |

<sup>*basename of the custom template file in `helm/alerting_payload_templates` without file extension </sup>

_Notes_:

- The value for `template` needs to match an existing file of the pattern
`helm/alert_payload_templates/<template>.json`; so if you want to use a predefined
one it needs to be one of `slack`, `keybase`, `opsgenie`, `msteams` or `ecs-1-12-0`.
- For Opsgenie you need to configure an additional
  `["Authorization: GenieKey <Your-Genie-Key>"]` header.
- For [Elastic Common Schema 1.12.0](https://www.elastic.co/guide/en/ecs/1.12/index.html) output, the `receiverUrl` has to be an HTTP/S log ingester, such as [Fluentd HTTP input](https://docs.fluentd.org/input/http) or [Logstash HTTP input](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-http.html). Also `customHeaders` needs to be set to `["Content-Type: application/json"]` for Fluentd HTTP endpoints.
- `failIfAlertSendingFails` only comes into play for requests that Connaisseur would have admitted as other requests would have been denied in the first place. The setting can come handy if you want to run Connaisseur in detection mode but still make sure that you get notified about what is going on in your cluster. **However, this setting will significantly impact cluster interaction for everyone (i.e. block any cluster change associated to an image) if the alert sending fails permanently, e.g. accidental deletion of your Slack Webhook App, GenieKey expired...**



## Example
For example, if you would like to receive notifications in Keybase whenever Connaisseur admits a request to your cluster, your alerting configuration would look similar to the following snippet:


```yaml title="helm/values.yaml"
alerting:
  admitRequest:
    receivers:
      - template: keybase
        receiverUrl: https://bots.keybase.io/webhookbot/<Your-Keybase-Hook-Token>
```

## Additional notes

### Creating a custom template

Along the lines of the templates that already exist you can easily define
custom templates for other endpoints. The following variables can be rendered
during runtime into the payload:

- `alert_message`
- `priority`
- `connaisseur_pod_id`
- `namespace`
- `cluster`
- `timestamp`
- `request_id`
- `images`

Referring to any of these variables in the templates works by Jinja2 notation
(e.g. `{{ timestamp }}`). You can update your payload dynamically by adding payload
fields in `yaml` representation in the `payloadFields` key which will be translated
to JSON by Helm as is. If your REST endpoint requires particular headers, you can
specify them as described above in `customHeaders`.

??? example "Payload fields in action"
    With payload fields, you can extend the same template depending on the receiver.
    For example, below Connaisseur's default Opsgenie template is used to send alerts that will be assigned to different users depending on whether the alert is for a successful admission or not.
    The `payloadFields` entries will be transformed to their JSON equivalents overwrite the respective entries of the template.

    ```yaml title="helm/values.yaml"
    alerting:
      admitRequest:
        receivers:
          - template: opsgenie
            receiverUrl: https://api.eu.opsgenie.com/v2/alerts
            priority: 4
            customHeaders: ["Authorization: GenieKey ABC-DEF"]
            payloadFields:
              responders:
                - username: "someone@testcompany.de"
                  type: user
      rejectRequest:
        receivers:
          - template: opsgenie
            receiverUrl: https://api.eu.opsgenie.com/v2/alerts
            priority: 4
            customHeaders: ["Authorization: GenieKey ABC-DEF"]
            payloadFields:
              responders:
                - username: "cert@testcompany.de"
                  type: user
    ```

    The resulting payload sent to the webhook endpoint will then contain the field content:

    ```json
    {
        ...
        "responders": [{"type": "user", "username": "cert@testcompany.de"}],
        ...
    }
    ```

Feel free to make a PR to share with the community if you add new neat templates for other third parties :pray:
