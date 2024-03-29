module server

import metrics
import web

// v1_metrics serves a Prometheus-compatible metrics endpoint.
['/api/v1/metrics'; get; markused]
fn (mut app App) v1_metrics() web.Result {
	if !app.conf.collect_metrics {
		return app.status(.not_found)
	}

	mut exporter := metrics.new_prometheus_exporter()
	exporter.load('vieter_', app.collector)

	// TODO stream to connection instead
	body := exporter.export_to_string() or { return app.status(.internal_server_error) }
	return app.body(.ok, 'text/plain', body)
}
