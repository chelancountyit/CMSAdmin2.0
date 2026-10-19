<cfoutput>
<div class="page-header d-flex justify-content-between align-items-center mb-4" style="display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; flex-wrap:wrap; margin-bottom:1.5rem;">
	<div>
		<div style="display:flex; align-items:center; gap:0.5rem; margin-bottom:0.35rem; flex-wrap:wrap;">
			<span class="badge badge-primary" style="font-size:0.72rem; text-transform:uppercase; letter-spacing:0.05em;">Settings &bull; Diagnostics</span>
			<span class="badge badge-success" style="font-size:0.72rem;">Live Telemetry</span>
			<span class="badge badge-neutral" style="font-size:0.72rem;">v#EncodeForHTML(diagnostics.server.wheelsVersion)#</span>
		</div>
		<h1 class="page-title" style="margin:0; font-size:1.5rem; font-weight:700;">System Info &amp; Diagnostics</h1>
		<p class="text-muted" style="margin:0.35rem 0 0; color:var(--admin-text-muted); font-size:0.92rem;">
			Real-time server telemetry, Java Virtual Machine (JVM) memory allocation, SQL Server database latency, disk capacity, and CFML runtime health.
		</p>
	</div>
	<div style="display:flex; gap:0.6rem; align-items:center; flex-wrap:wrap;">
		<a href="?refresh=true" class="btn btn-outline-secondary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="refresh-cw", size=14)#
			<span>Refresh Telemetry</span>
		</a>
		<a href="/login?reload=true&password=chelancms" class="btn btn-outline-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
			#svgIcon(name="rotate-ccw", size=14)#
			<span>Reload Framework</span>
		</a>
	</div>
</div>

<!--- Metric KPI Overview Cards --->
<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(240px, 1fr)); gap:1rem; margin-bottom:1.5rem;">
	
	<!--- JVM Memory Card --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
		<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.6rem;">
			<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.03em;">JVM Heap Memory</span>
			<span style="color:var(--admin-primary);">#svgIcon(name="cpu", size=18)#</span>
		</div>
		<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.4rem;">
			#diagnostics.jvm.usedMB# <span style="font-size:0.85rem; font-weight:500; color:var(--admin-text-muted);">/ #diagnostics.jvm.maxMB# MB</span>
		</div>
		<div style="height:6px; width:100%; background:var(--admin-bg); border-radius:3px; overflow:hidden; margin-bottom:0.4rem;">
			<div style="height:100%; width:#diagnostics.jvm.percent#%; background:<cfif diagnostics.jvm.percent gt 85>var(--admin-danger)<cfelseif diagnostics.jvm.percent gt 65>var(--admin-warning)<cfelse>var(--admin-primary)</cfif>; border-radius:3px;"></div>
		</div>
		<div style="display:flex; justify-content:space-between; font-size:0.75rem; color:var(--admin-text-muted);">
			<span>#diagnostics.jvm.percent#% Utilized</span>
			<span>#diagnostics.jvm.freeMB# MB Free</span>
		</div>
	</div>

	<!--- Disk Storage Card --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
		<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.6rem;">
			<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.03em;">Storage Capacity</span>
			<span style="color:var(--admin-info);">#svgIcon(name="hard-drive", size=18)#</span>
		</div>
		<div style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.4rem;">
			#diagnostics.disk.freeGB# <span style="font-size:0.85rem; font-weight:500; color:var(--admin-text-muted);">GB Free</span>
		</div>
		<div style="height:6px; width:100%; background:var(--admin-bg); border-radius:3px; overflow:hidden; margin-bottom:0.4rem;">
			<div style="height:100%; width:#diagnostics.disk.percent#%; background:var(--admin-info); border-radius:3px;"></div>
		</div>
		<div style="display:flex; justify-content:space-between; font-size:0.75rem; color:var(--admin-text-muted);">
			<span>#diagnostics.disk.usedGB# GB of #diagnostics.disk.totalGB# GB</span>
			<span>#diagnostics.disk.percent#% Used</span>
		</div>
	</div>

	<!--- SQL Server Health Card --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
		<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.6rem;">
			<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.03em;">Database Latency</span>
			<span style="color:var(--admin-success);">#svgIcon(name="database", size=18)#</span>
		</div>
		<div style="display:flex; align-items:baseline; gap:0.4rem; margin-bottom:0.4rem;">
			<span style="font-size:1.5rem; font-weight:700; color:var(--admin-text-main);">#diagnostics.db.latencyMs#</span>
			<span style="font-size:0.85rem; font-weight:500; color:var(--admin-text-muted);">ms</span>
			<span class="badge <cfif diagnostics.db.connected>badge-success<cfelse>badge-danger</cfif>" style="font-size:0.7rem; margin-left:auto;">
				<cfif diagnostics.db.connected>CONNECTED<cfelse>OFFLINE</cfif>
			</span>
		</div>
		<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.4rem;">
			<span>Database: <strong>#EncodeForHTML(diagnostics.db.dbName)#</strong></span>
		</div>
		<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.15rem;">
			<span>#diagnostics.db.tableCount# Audited Tables Registered</span>
		</div>
	</div>

	<!--- Server Uptime Card --->
	<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
		<div style="display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:0.6rem;">
			<span style="font-size:0.8rem; font-weight:600; color:var(--admin-text-muted); text-transform:uppercase; letter-spacing:0.03em;">Process Uptime</span>
			<span style="color:var(--admin-warning);">#svgIcon(name="clock", size=18)#</span>
		</div>
		<div style="font-size:1.4rem; font-weight:700; color:var(--admin-text-main); margin-bottom:0.4rem;">
			#diagnostics.server.uptime#
		</div>
		<div style="font-size:0.8rem; color:var(--admin-text-muted); margin-top:0.4rem;">
			<span>Engine: <strong>#EncodeForHTML(diagnostics.server.engine)#</strong></span>
		</div>
		<div style="font-size:0.75rem; color:var(--admin-text-muted); margin-top:0.15rem;">
			<span>Host: <code>#EncodeForHTML(diagnostics.os.host)#</code></span>
		</div>
	</div>

</div>

<!--- Main Diagnostics Telemetry Grid --->
<div style="display:grid; grid-template-columns: 8fr 4fr; gap:1.5rem; align-items:start;">
	
	<!--- Left Column: Detailed Telemetry Cards --->
	<div style="display:flex; flex-direction:column; gap:1.5rem;">
		
		<!--- Telemetry Card 1: CFML Runtime & Application Framework --->
		<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
				<span style="color:var(--admin-primary);">#svgIcon(name="terminal", size=20)#</span>
				<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">CFML Runtime &amp; Framework Environment</h2>
			</div>

			<table class="table" style="width:100%; margin:0; border-collapse:collapse; font-size:0.875rem;">
				<tbody>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main); width:35%;">CFML Engine</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							<strong>#EncodeForHTML(diagnostics.server.engine)#</strong> (v#EncodeForHTML(diagnostics.server.version)#)
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">License Level</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							<span class="badge badge-neutral" style="font-size:0.75rem;">#EncodeForHTML(diagnostics.server.level)#</span>
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">CFWheels Framework</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							v#EncodeForHTML(diagnostics.server.wheelsVersion)# &bull; Environment: <strong>#EncodeForHTML(diagnostics.server.wheelsEnv)#</strong>
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Webroot Physical Path</td>
						<td style="padding:0.65rem 0; font-family:monospace; font-size:0.82rem; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.server.webroot)#
						</td>
					</tr>
					<tr>
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Process Uptime</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#diagnostics.server.uptime#
						</td>
					</tr>
				</tbody>
			</table>
		</div>

		<!--- Telemetry Card 2: Java Virtual Machine (JVM) --->
		<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
				<span style="color:var(--admin-primary);">#svgIcon(name="cpu", size=20)#</span>
				<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Java Virtual Machine (JVM) &amp; Memory Allocation</h2>
			</div>

			<table class="table" style="width:100%; margin:0; border-collapse:collapse; font-size:0.875rem;">
				<tbody>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main); width:35%;">Java Version &amp; Vendor</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.jvm.version)# (#EncodeForHTML(diagnostics.jvm.vendor)#)
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">JVM Implementation</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.jvm.vmName)#
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Maximum Heap (Xmx)</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							<strong>#diagnostics.jvm.maxMB# MB</strong>
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Currently Allocated (Total)</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#diagnostics.jvm.totalMB# MB
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Active Used Memory</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#diagnostics.jvm.usedMB# MB (#diagnostics.jvm.percent#% of maximum heap)
						</td>
					</tr>
					<tr>
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Free Heap Available</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#diagnostics.jvm.freeMB# MB
						</td>
					</tr>
				</tbody>
			</table>
		</div>

		<!--- Telemetry Card 3: Microsoft SQL Server Database Health --->
		<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
				<div style="display:flex; align-items:center; gap:0.6rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="database", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Microsoft SQL Server Database Connection</h2>
				</div>
				<span class="badge <cfif diagnostics.db.connected>badge-success<cfelse>badge-danger</cfif>" style="font-size:0.75rem;">
					<cfif diagnostics.db.connected>HEALTHY &bull; #diagnostics.db.latencyMs#ms<cfelse>ERROR</cfif>
				</span>
			</div>

			<cfif diagnostics.db.connected>
				<table class="table" style="width:100%; margin:0 0 1rem; border-collapse:collapse; font-size:0.875rem;">
					<tbody>
						<tr style="border-bottom:1px solid var(--admin-border);">
							<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main); width:35%;">Database Name</td>
							<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
								<strong>#EncodeForHTML(diagnostics.db.dbName)#</strong>
							</td>
						</tr>
						<tr style="border-bottom:1px solid var(--admin-border);">
							<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Connection Latency</td>
							<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
								#diagnostics.db.latencyMs# ms (round-trip ping)
							</td>
						</tr>
						<tr style="border-bottom:1px solid var(--admin-border);">
							<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Server Database Time</td>
							<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
								#EncodeForHTML(diagnostics.db.serverTime)#
							</td>
						</tr>
						<tr style="border-bottom:1px solid var(--admin-border);">
							<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Registered Tables</td>
							<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
								#diagnostics.db.tableCount# tables registered in <code>dbo</code> schema
							</td>
						</tr>
					</tbody>
				</table>

				<div style="padding:0.85rem; background:##0f172a; border-radius:var(--radius-md); font-family:monospace; font-size:0.78rem; color:##e2e8f0; line-height:1.5; overflow-x:auto;">
					#EncodeForHTML(diagnostics.db.sqlVersion)#
				</div>
			<cfelse>
				<div class="alert alert-danger" style="margin:0; padding:1rem; border-radius:var(--radius-md); font-size:0.85rem;">
					<strong>Database Error:</strong> #EncodeForHTML(diagnostics.db.errorMessage)#
				</div>
			</cfif>
		</div>

		<!--- Telemetry Card 4: Operating System & Storage --->
		<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<div style="display:flex; align-items:center; gap:0.6rem; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem;">
				<span style="color:var(--admin-primary);">#svgIcon(name="hard-drive", size=20)#</span>
				<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Host Operating System &amp; Disk Volume</h2>
			</div>

			<table class="table" style="width:100%; margin:0; border-collapse:collapse; font-size:0.875rem;">
				<tbody>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main); width:35%;">Operating System</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.os.name)# (Build #EncodeForHTML(diagnostics.os.version)#, #EncodeForHTML(diagnostics.os.arch)#)
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Host Name</td>
						<td style="padding:0.65rem 0; font-family:monospace; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.os.host)#
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Storage Root Path</td>
						<td style="padding:0.65rem 0; font-family:monospace; font-size:0.82rem; color:var(--admin-text-muted);">
							#EncodeForHTML(diagnostics.disk.path)#
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Drive Capacity</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							#diagnostics.disk.totalGB# GB Total &bull; #diagnostics.disk.freeGB# GB Free (#diagnostics.disk.percent#% in use)
						</td>
					</tr>
				</tbody>
			</table>
		</div>

		<!--- Telemetry Card 5: Automated Publishing & Expiration Scheduler --->
		<div class="card" style="padding:1.5rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:1.25rem; border-bottom:1px solid var(--admin-border); padding-bottom:0.75rem; flex-wrap:wrap; gap:0.5rem;">
				<div style="display:flex; align-items:center; gap:0.6rem;">
					<span style="color:var(--admin-primary);">#svgIcon(name="clock", size=20)#</span>
					<h2 style="margin:0; font-size:1.05rem; font-weight:700; color:var(--admin-text-main);">Automated Publishing &amp; Expiration Worker</h2>
				</div>
				<button type="button" id="btnRunSchedulerNow" class="btn btn-outline-primary btn-sm" style="display:inline-flex; align-items:center; gap:0.4rem;">
					#svgIcon(name="play", size=13)#
					<span>Run Evaluator Now</span>
				</button>
			</div>

			<cfset sch = diagnostics.scheduler ?: {}>
			<div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(130px, 1fr)); gap:0.75rem; margin-bottom:1rem;">
				<div style="padding:0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); border:1px solid var(--admin-border); text-align:center;">
					<div style="font-size:0.72rem; text-transform:uppercase; font-weight:600; color:var(--admin-text-muted);">Pending Pages</div>
					<div style="font-size:1.25rem; font-weight:700; color:var(--admin-text-main); margin-top:0.25rem;">
						#Val(sch.pages_pending_publish ?: 0)# <span style="font-size:0.75rem; font-weight:normal; color:var(--admin-text-muted);">/ #Val(sch.pages_pending_unpublish ?: 0)#</span>
					</div>
					<div style="font-size:0.68rem; color:var(--admin-text-muted);">Pub / Unpub</div>
				</div>

				<div style="padding:0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); border:1px solid var(--admin-border); text-align:center;">
					<div style="font-size:0.72rem; text-transform:uppercase; font-weight:600; color:var(--admin-text-muted);">Pending Articles</div>
					<div style="font-size:1.25rem; font-weight:700; color:var(--admin-text-main); margin-top:0.25rem;">
						#Val(sch.articles_pending_publish ?: 0)# <span style="font-size:0.75rem; font-weight:normal; color:var(--admin-text-muted);">/ #Val(sch.articles_pending_unpublish ?: 0)#</span>
					</div>
					<div style="font-size:0.68rem; color:var(--admin-text-muted);">Pub / Unpub</div>
				</div>

				<div style="padding:0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); border:1px solid var(--admin-border); text-align:center;">
					<div style="font-size:0.72rem; text-transform:uppercase; font-weight:600; color:var(--admin-text-muted);">Pending Events</div>
					<div style="font-size:1.25rem; font-weight:700; color:var(--admin-text-main); margin-top:0.25rem;">
						#Val(sch.events_pending_publish ?: 0)# <span style="font-size:0.75rem; font-weight:normal; color:var(--admin-text-muted);">/ #Val(sch.events_pending_unpublish ?: 0)#</span>
					</div>
					<div style="font-size:0.68rem; color:var(--admin-text-muted);">Pub / Unpub</div>
				</div>

				<div style="padding:0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); border:1px solid var(--admin-border); text-align:center;">
					<div style="font-size:0.72rem; text-transform:uppercase; font-weight:600; color:var(--admin-text-muted);">Pending Jobs</div>
					<div style="font-size:1.25rem; font-weight:700; color:var(--admin-text-main); margin-top:0.25rem;">
						#Val(sch.jobs_pending_publish ?: 0)# <span style="font-size:0.75rem; font-weight:normal; color:var(--admin-text-muted);">/ #Val(sch.jobs_pending_unpublish ?: 0)#</span>
					</div>
					<div style="font-size:0.68rem; color:var(--admin-text-muted);">Pub / Unpub</div>
				</div>
			</div>

			<table class="table" style="width:100%; margin:0; border-collapse:collapse; font-size:0.875rem;">
				<tbody>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main); width:35%;">Throttled Worker Interval</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							Every <strong>60 seconds</strong> on incoming request start (Mutex lock protected)
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">Last Execution Timestamp</td>
						<td style="padding:0.65rem 0; font-family:monospace; color:var(--admin-text-muted);">
							#EncodeForHTML(sch.lastRunAt ?: "Awaiting first run")#
						</td>
					</tr>
					<tr style="border-bottom:1px solid var(--admin-border);">
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">REST Automation Endpoint</td>
						<td style="padding:0.65rem 0; font-family:monospace; font-size:0.82rem; color:var(--admin-text-muted);">
							<code>GET /scheduler/run</code> or <code>GET /api/v1/scheduler/run</code>
						</td>
					</tr>
					<tr>
						<td style="padding:0.65rem 0; font-weight:600; color:var(--admin-text-main);">State Transitions Supported</td>
						<td style="padding:0.65rem 0; color:var(--admin-text-muted);">
							<code>Scheduled &rarr; Active/Published</code> &bull; <code>Active &rarr; Archived/Closed</code> (Pages, Articles, Events, Careers)
						</td>
					</tr>
				</tbody>
			</table>
		</div>

	</div>

	<!--- Sidebar Actions & Navigation Column --->
	<div style="display:flex; flex-direction:column; gap:1.25rem;">
		
		<!--- Refresh & Reload Action Card --->
		<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<h3 style="margin:0 0 0.85rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
				#svgIcon(name="activity", size=16)#
				<span>Maintenance Actions</span>
			</h3>
			<p style="font-size:0.82rem; color:var(--admin-text-muted); margin-bottom:1rem; line-height:1.45;">
				Trigger immediate framework reloads, clear caching pools, or sample fresh hardware telemetry.
			</p>
			<div style="display:flex; flex-direction:column; gap:0.5rem;">
				<a href="?sample=true" class="btn btn-primary" style="display:inline-flex; align-items:center; justify-content:center; gap:0.5rem; font-weight:600; padding:0.6rem 1rem;">
					#svgIcon(name="refresh-cw", size=15)#
					<span>Sample Live Metrics</span>
				</a>
				<a href="/login?reload=true&password=chelancms" class="btn btn-outline-secondary" style="display:inline-flex; align-items:center; justify-content:center; gap:0.5rem; font-weight:600; padding:0.6rem 1rem;">
					#svgIcon(name="rotate-ccw", size=15)#
					<span>Flush Framework Cache</span>
				</a>
			</div>
		</div>

		<!--- Settings Navigation Hub --->
		<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-surface); box-shadow:var(--shadow-sm);">
			<h3 style="margin:0 0 0.85rem; font-size:0.95rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.5rem;">
				#svgIcon(name="settings", size=16)#
				<span>Settings Modules</span>
			</h3>
			<ul style="list-style:none; padding:0; margin:0; display:flex; flex-direction:column; gap:0.4rem;">
				<li>
					<a href="#urlFor(controller='settings', action='general')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="globe", size=15)# General Settings
						</span>
						<span style="color:var(--admin-text-muted); font-size:0.75rem;">Core Identity</span>
					</a>
				</li>
				<li>
					<a href="#urlFor(controller='settings', action='seo')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="search", size=15)# Reading &amp; SEO
						</span>
						<span style="color:var(--admin-text-muted); font-size:0.75rem;">Meta &bull; GA4</span>
					</a>
				</li>
				<li>
					<a href="#urlFor(controller='settings', action='media')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="image", size=15)# Media Sizes
						</span>
						<span style="color:var(--admin-text-muted); font-size:0.75rem;">Upload Caps</span>
					</a>
				</li>
				<li>
					<a href="#urlFor(controller='settings', action='system')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); background:var(--admin-bg); color:var(--admin-primary); font-weight:600; font-size:0.85rem; text-decoration:none;">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="cpu", size=15)# System Info
						</span>
						<span class="badge badge-primary" style="font-size:0.7rem;">Active</span>
					</a>
				</li>
				<li>
					<a href="#urlFor(controller='documentation', action='startup')#" style="display:flex; align-items:center; justify-content:space-between; padding:0.5rem 0.75rem; border-radius:var(--radius-md); color:var(--admin-text-main); font-size:0.85rem; text-decoration:none; transition:background 0.15s ease;" onmouseover="this.style.background='var(--admin-bg)'" onmouseout="this.style.background='transparent'">
						<span style="display:flex; align-items:center; gap:0.5rem;">
							#svgIcon(name="book", size=15)# Docs: Front-End (.css)
						</span>
						<span style="color:var(--admin-text-muted); font-size:0.75rem;">Docs</span>
					</a>
				</li>
			</ul>
		</div>

		<!--- Security Compliance Box --->
		<div class="card" style="padding:1.25rem; border:1px solid var(--admin-border); border-radius:var(--radius-lg); background:var(--admin-bg); box-shadow:none;">
			<h4 style="margin:0 0 0.5rem; font-size:0.85rem; font-weight:700; color:var(--admin-text-main); display:flex; align-items:center; gap:0.4rem;">
				#svgIcon(name="shield", size=15)#
				<span>Audit Compliance</span>
			</h4>
			<p style="font-size:0.8rem; color:var(--admin-text-muted); margin:0; line-height:1.45;">
				Diagnostics telemetry is restricted to authenticated administrators and complies with Washington State Department of Enterprise Services standards.
			</p>
		</div>
	</div>

</div>
</cfoutput>

<script>
document.addEventListener("DOMContentLoaded", function () {
	var btnRun = document.getElementById("btnRunSchedulerNow");
	if (!btnRun) return;

	btnRun.addEventListener("click", function () {
		btnRun.disabled = true;
		var origHtml = btnRun.innerHTML;
		btnRun.innerHTML = '<span>Running Evaluator...</span>';

		fetch("/api/v1/scheduler/run", {
			method: "POST",
			headers: { "Accept": "application/json" },
			credentials: "same-origin"
		})
		.then(function (r) { return r.json(); })
		.then(function (data) {
			btnRun.disabled = false;
			btnRun.innerHTML = origHtml;
			var success = Boolean(data && (data.success || data.SUCCESS));
			var msg = (data && data.message) ? data.message : "Evaluator execution finished.";
			var details = (data && data.data) ? data.data : (data ? data.result : null);
			if (details && typeof details === "object") {
				msg += " (" + (details.published || 0) + " published, " + (details.archived || 0) + " archived/closed across modules)";
			}
			if (typeof window.showToast === "function") {
				window.showToast(msg, success ? "success" : "info");
			} else if (typeof window.adminAlert === "function") {
				window.adminAlert(msg, { title: "Publishing Scheduler", type: success ? "success" : "info" });
			}
			setTimeout(function () { window.location.reload(); }, 1200);
		})
		.catch(function (err) {
			btnRun.disabled = false;
			btnRun.innerHTML = origHtml;
			if (typeof window.showToast === "function") {
				window.showToast("Failed to run evaluator: " + err.message, "danger");
			} else if (typeof window.adminAlert === "function") {
				window.adminAlert("Failed to run evaluator: " + err.message, { title: "Scheduler Error", type: "danger" });
			}
		});
	});
});
</script>

