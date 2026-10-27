<!DOCTYPE html>
<html lang="en">
	<head>
		<meta charset="utf-8">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<title>Online Form - Chelan County Official Services</title>
		
		<link rel="preconnect" href="https://fonts.googleapis.com">
		<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
		<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">

		<style>
			:root {
				--primary: #0073aa;
				--primary-dark: #005a87;
				--bg: #f8fafc;
				--surface: #ffffff;
				--border: #cbd5e1;
				--border-subtle: #e2e8f0;
				--text: #0f172a;
				--text-muted: #475569;
				--success: #15803d;
				--success-light: #dcfce7;
				--danger: #b91c1c;
				--danger-light: #fee2e2;
				--warning: #b45309;
				--warning-light: #fef3c7;
				--radius: 10px;
			}
			*, *::before, *::after { box-sizing: border-box; }
			body {
				margin: 0;
				padding: 2rem 1rem !important;
				font-family: "Plus Jakarta Sans", system-ui, -apple-system, sans-serif;
				/*background-color: var(--bg);*/
				color: var(--text);
				font-size: 15px;
				line-height: 1.5;
			}
			/* When embedded in an iframe on public pages, eliminate outer page margin and avoid clipping */
			html.is-embedded, body.is-embedded {
				margin: 0 !important;
				padding: 0.25rem 0 0.25rem 0 !important;
				background: transparent !important;
				overflow-x: hidden !important;
				overflow-y: hidden !important;
				height: auto !important;
				min-height: 0 !important;
			}
			body.is-embedded .form-wrapper {
				max-width: 100% !important;
				margin: 0 !important;
				padding: 0 !important;
			}
			body.is-embedded .form-card {
				box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
				margin-bottom: 0 !important;
			}
			#wheels-debugbar {
				display: none !important;
			}
			.form-wrapper {
				max-width: 900px;
				margin: 0 auto;
			}
			.official-bar {
				display: flex;
				align-items: center;
				justify-content: space-between;
				padding: 0.5rem 0.25rem 0.85rem 0.25rem;
				font-size: 0.8rem;
				color: var(--text-muted);
				flex-wrap: wrap;
				gap: 0.5rem;
			}
			.official-badge {
				display: inline-flex;
				align-items: center;
				gap: 0.4rem;
				font-weight: 600;
				color: var(--primary);
			}
			.compliance-tags {
				display: inline-flex;
				align-items: center;
				gap: 0.5rem;
			}
			.comp-tag {
				display: inline-flex;
				align-items: center;
				gap: 0.25rem;
				padding: 2px 7px;
				border-radius: 4px;
				font-size: 0.7rem;
				font-weight: 600;
			}
			.comp-tag.wcag { background: #dcfce7; color: #15803d; }
			.comp-tag.spam { background: #e0f2fe; color: #0369a1; }

			.form-card {
				background: var(--surface);
				border: 1px solid var(--border);
				border-radius: var(--radius);
				box-shadow: 0 4px 6px -1px rgba(0,0,0,0.06), 0 2px 4px -1px rgba(0,0,0,0.04);
				overflow: hidden;
				border-top: 5px solid var(--primary);
			}
			.form-header {
				padding: 2rem;
				border-bottom: 1px solid var(--border-subtle);
				background: linear-gradient(to bottom, #ffffff, #f8fafc);
			}
			.form-title {
				margin: 0 0 0.5rem 0;
				font-size: 1.55rem;
				font-weight: 700;
				color: var(--text);
				line-height: 1.3;
			}
			.form-desc {
				margin: 0;
				color: var(--text-muted);
				font-size: 0.95rem;
				line-height: 1.6;
			}
			.form-body {
				padding: 2rem;
				display: flex;
				flex-direction: column;
				gap: 1.35rem;
			}
			.fields-list {
				display: grid;
				grid-template-columns: repeat(12, minmax(0, 1fr));
				gap: 1.25rem;
				width: 100%;
				align-items: start;
			}
			.field-group {
				display: flex;
				flex-direction: column;
				box-sizing: border-box;
				min-width: 0;
				width: auto;
				max-width: none;
			}
			.field-col-100 {
				grid-column: span 12;
			}
			.field-col-50 {
				grid-column: span 6;
			}
			.field-col-33 {
				grid-column: span 4;
			}
			@media (max-width: 768px) {
				.field-col-50,
				.field-col-33 {
					grid-column: span 12;
				}
			}
			.field-label {
				font-weight: 600;
				font-size: 0.9rem;
				margin-bottom: 0.4rem;
				color: var(--text);
			}
			.required-star {
				color: var(--danger);
				font-weight: bold;
				margin-left: 2px;
			}
			.field-subtext {
				font-size: 0.8rem;
				color: var(--text-muted);
				margin-top: 0.35rem;
				line-height: 1.4;
			}
			.form-control {
				width: 100%;
				box-sizing: border-box;
				padding: 0.65rem 0.85rem;
				font-size: 0.95rem;
				border: 1.5px solid var(--border);
				border-radius: 6px;
				font-family: inherit;
				color: var(--text);
				background: #fff;
				outline: none;
				transition: border-color 0.2s, box-shadow 0.2s;
			}
			.form-control:focus,
			.form-control:focus-visible {
				border-color: var(--primary);
				outline: 2px solid var(--primary) !important;
				outline-offset: 2px !important;
			}
			textarea.form-control {
				min-height: 105px;
				line-height: 1.5;
				resize: vertical;
			}
			
			/* ADA WCAG Accessible Fieldset & Legend for Choice Groups */
			.form-fieldset {
				border: none;
				margin: 0;
				padding: 0;
				min-width: 0;
				width: 100%;
				display: block;
			}
			.form-legend {
				float: left;
				width: 100%;
				display: block;
				font-weight: 600;
				font-size: 0.9rem;
				margin-bottom: 0.5rem;
				color: var(--text);
				padding: 0;
				line-height: 1.4;
			}
			.form-fieldset > *:not(.form-legend) {
				clear: both;
			}
			.form-options-wrap {
				display: flex;
				flex-direction: column;
				gap: 0.5rem;
				clear: both;
				width: 100%;
			}
			.form-option-item {
				display: flex;
				align-items: center;
				gap: 0.6rem;
				font-size: 0.9rem;
				color: var(--text);
				cursor: pointer;
				padding: 0.25rem 0.5rem;
				border-radius: 4px;
				transition: background-color 0.15s;
			}
			.form-option-item:hover {
				background-color: rgba(0, 115, 170, 0.05);
			}
			.form-option-item input {
				width: 18px;
				height: 18px;
				accent-color: var(--primary);
				cursor: pointer;
				margin: 0;
				flex-shrink: 0;
			}

			/* Address Block Component */
			.form-address-group {
				width: 100%;
			}
			.form-address-fields {
				display: flex;
				flex-direction: column;
				gap: 0.55rem;
				clear: both;
				width: 100%;
			}
			.form-address-row-city-state-zip {
				display: flex;
				gap: 0.55rem;
				width: 100%;
			}
			.form-address-col-city {
				flex: 5;
				min-width: 0;
			}
			.form-address-col-state {
				flex: 2;
				min-width: 60px;
			}
			.form-address-col-zip {
				flex: 3;
				min-width: 85px;
			}
			@media (max-width: 520px) {
				.form-address-row-city-state-zip {
					flex-direction: column;
					gap: 0.55rem;
				}
			}

			/* Switch Component */
			.form-switch-row {
				display: flex;
				align-items: center;
				justify-content: space-between;
				gap: 1rem;
				width: 100%;
			}

			/* Interactive Rating Stars */
			.interactive-star-rating {
				display: flex;
				gap: 0.4rem;
				color: #cbd5e1;
				cursor: pointer;
				padding: 0.25rem 0;
			}
			.star-btn {
				background: none;
				border: none;
				padding: 0;
				font-size: 1.6rem;
				line-height: 1;
				cursor: pointer;
				color: #cbd5e1;
				transition: color 0.2s;
			}

			/* Digital Signature Capture */
			.form-signature-box {
				border: 1px solid var(--border);
				border-radius: var(--radius);
				padding: 0.5rem;
				background: #fff;
			}
			.form-signature-input {
				width: 100%;
				box-sizing: border-box;
				border: none;
				outline: none;
				font-family: 'Brush Script MT', cursive, sans-serif;
				font-size: 1.4rem;
				color: var(--primary);
				padding: 0.4rem;
			}

			/* Static Paragraph Content / Instructions Block */
			.form-paragraph-block {
				padding: 0.9rem 1.15rem;
				background: var(--bg);
				border-left: 4px solid var(--primary);
				border-radius: 6px;
				margin: 0.25rem 0;
			}
			.form-paragraph-block.style-callout { background: #f0f9ff; border-left-color: var(--primary); }
			.form-paragraph-block.style-warning { background: var(--warning-light); border-left-color: var(--warning); color: #78350f; }
			.form-paragraph-block.style-legal { background: #f1f5f9; border-left-color: #94a3b8; font-size: 0.85rem; }
			.form-paragraph-text {
				margin: 0;
				font-size: 0.9rem;
				line-height: 1.6;
				color: inherit;
				white-space: pre-line;
			}

			/* Submit Button & Cooldown State */
			.btn-submit {
				background: var(--primary);
				color: #fff;
				border: none;
				padding: 0.75rem 2rem;
				border-radius: 6px;
				font-weight: 600;
				font-size: 1rem;
				cursor: pointer;
				transition: background-color 0.2s, opacity 0.2s;
				display: inline-flex;
				align-items: center;
				gap: 0.5rem;
			}
			.btn-submit:hover { background: var(--primary-dark); }
			.btn-submit:focus-visible {
				outline: 2px solid var(--primary) !important;
				outline-offset: 3px !important;
			}
			.btn-submit.btn-submitting {
				pointer-events: none;
				opacity: 0.85;
			}
			.btn-submit.btn-submitting::before {
				content: "";
				display: inline-block;
				width: 15px;
				height: 15px;
				border: 2px solid rgba(255, 255, 255, 0.4);
				border-top-color: #ffffff;
				border-radius: 50%;
				animation: spin 0.75s linear infinite;
			}
			@keyframes spin { to { transform: rotate(360deg); } }

			/* Screen Reader Only Utility */
			.sr-only {
				position: absolute !important;
				width: 1px !important;
				height: 1px !important;
				padding: 0 !important;
				margin: -1px !important;
				overflow: hidden !important;
				clip: rect(0, 0, 0, 0) !important;
				white-space: nowrap !important;
				border: 0 !important;
			}

			/* Anti-Spam Honeypot Bot Trap (Invisible to humans, catches robotic spiders) */
			.hp-trap {
				position: absolute !important;
				left: -9999px !important;
				top: -9999px !important;
				width: 1px !important;
				height: 1px !important;
				overflow: hidden !important;
				opacity: 0 !important;
			}

			/* Live Region Alert Banner */
			.alert-banner {
				padding: 0.95rem 1.25rem;
				border-radius: 8px;
				font-size: 0.88rem;
				font-weight: 500;
				display: flex;
				align-items: flex-start;
				gap: 0.75rem;
				line-height: 1.5;
				border: 1px solid var(--border);
				border-left: 5px solid var(--primary);
				background: var(--surface);
				color: var(--text-main);
				box-shadow: 0 1px 3px rgba(0,0,0,0.05);
			}
			.alert-banner.error {
				background: #fef2f2;
				border-color: #fecaca;
				border-left-color: var(--danger);
				color: #991b1b;
			}
			.alert-banner.warning {
				background: #fffbeb;
				border-color: #fde68a;
				border-left-color: var(--warning);
				color: #854d0e;
			}
			.alert-banner.success {
				background: #f0fdf4;
				border-color: #bbf7d0;
				border-left-color: var(--success);
				color: #14532d;
			}
			.alert-banner.info {
				background: #f0f9ff;
				border-color: #bae6fd;
				border-left-color: var(--primary);
				color: #075985;
			}

			/* Confirmation Screen */
			.success-card {
				background: var(--surface);
				border: 1px solid var(--border);
				border-top: 5px solid var(--success);
				border-radius: var(--radius);
				padding: 3rem 2rem;
				text-align: center;
				box-shadow: 0 4px 6px -1px rgba(0,0,0,0.06);
			}
			.success-icon {
				width: 64px;
				height: 64px;
				border-radius: 50%;
				background: var(--success-light);
				color: var(--success);
				display: inline-flex;
				align-items: center;
				justify-content: center;
				margin-bottom: 1.25rem;
			}
		</style>
	</head>
	<body>
		<div class="form-wrapper">
			<div class="official-bar">
				<span class="official-badge">
					<svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
					Chelan County Official Online Intake
				</span>
			</div>

			<div class="form-card" id="formCard">
				<div class="form-header">
					<h1 class="form-title" id="formTitle">Online Form</h1>
					<p class="form-desc" id="formDesc">Please fill out the requested information below.</p>
				</div>

				<form class="form-body" id="publicForm" aria-labelledby="formTitle" aria-describedby="formDesc" novalidate>
					<!-- Accessible Alert Banner for Errors and Anti-Spam notices -->
					<div id="formAlertBanner" class="alert-banner" role="alert" aria-live="polite" style="display:none;"></div>

					<!-- Anti-Spam Honeypot Bot Trap -->
					<div class="hp-trap" aria-hidden="true">
						<label for="_chelan_gov_verify">Do not fill this field if you are a human</label>
						<input type="text" id="_chelan_gov_verify" name="_chelan_gov_verify" tabindex="-1" autocomplete="off" value="">
					</div>

					<!-- Anti-Spam Speed Trap Form Load Token & Form Identity Metadata -->
					<input type="hidden" id="_cf_form_load_time" name="_cf_form_load_time" value="">
					<input type="hidden" id="_form_id" name="_form_id" value="">
					<input type="hidden" id="_form_key" name="_form_key" value="">
					<input type="hidden" id="_form_slug" name="_form_slug" value="">

					<!-- Dynamic Accessible Form Fields -->
					<div id="dynamicFields" class="fields-list"></div>

					<div style="margin-top:1rem; padding-top:1.5rem; padding-bottom:1.5rem; border-top:1px solid var(--border-subtle); display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem;">
						<button type="submit" class="btn-submit" id="btnSubmit">Submit Form</button>
						<span style="font-size:0.8rem; color:var(--text-muted); display:inline-flex; align-items:center; gap:0.35rem;">
							<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
							256-Bit SSL Encrypted Submission &bull; Human Verified
						</span>
					</div>
				</form>
			</div>

			<div class="success-card" id="successCard" style="display: none;" role="region" aria-label="Submission Confirmation">
				<div class="success-icon">
					<svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>
				</div>
				<h2 style="margin: 0 0 0.5rem 0; font-size:1.4rem; color:var(--text);" id="successHeading" tabindex="-1">Submission Received!</h2>
				<p style="color:var(--text-muted); margin:0 0 1.5rem 0; font-size:0.95rem;" id="successMsg">
					Thank you! Your information has been successfully received by Chelan County.
				</p>
				<div id="successMeta" style="display:inline-flex; flex-wrap:wrap; justify-content:center; gap:1.25rem; background:var(--bg); border:1px solid var(--border); border-radius:6px; padding:0.85rem 1.5rem; font-size:0.825rem; color:var(--text); margin-bottom:1.75rem;">
					<div><strong>Reference Number:</strong> <span id="metaRefId" style="font-family:monospace; color:var(--primary); font-weight:600;"></span></div>
					<div><strong>Submitted At:</strong> <span id="metaTime"></span></div>
					<div><strong>Anti-Spam:</strong> <span style="color:var(--success); font-weight:600;">Verified Human</span></div>
				</div>
				<div>
					<button type="button" class="btn-submit" onclick="location.reload()" style="padding:0.65rem 1.75rem; font-size:0.9rem;">
						Submit Another Response
					</button>
				</div>
			</div>
		</div>

		<script>
			(function() {
				// Detect if rendered inside an iframe on public pages
				if (window.self !== window.top) {
					document.documentElement.classList.add("is-embedded");
					document.body.classList.add("is-embedded");
				}

				// Post actual form content height to parent window without reading documentElement.scrollHeight (which causes feedback loops)
				let lastSentHeight = 0;
				function sendHeightToParent(force) {
					if (window.parent && window.parent !== window) {
						var wrapper = document.querySelector(".form-wrapper") || document.querySelector(".form-card");
						if (!wrapper) return;
						var rectHeight = Math.ceil(wrapper.getBoundingClientRect().height);
						var offsetHeight = wrapper.offsetHeight || 0;
						var h = Math.max(rectHeight, offsetHeight);
						if (!h || h <= 0) return;
						var hWithBuffer = h + 12;
						if (!force && Math.abs(hWithBuffer - lastSentHeight) < 3) return;
						lastSentHeight = hWithBuffer;
						window.parent.postMessage({
							type: "chelan-form-resize",
							height: hWithBuffer
						}, "*");
					}
				}

				// Record exact form render timestamp for submission speed-trap anti-spam check
				document.getElementById("_cf_form_load_time").value = Date.now();

				const TEMPLATE_PRESETS = {
					contact: {
						title: "General Contact & Inquiry Form",
						description: "Please submit your inquiry or message. Our office typically responds within 1 to 2 business days.",
						submitText: "Send Message",
						themeColor: "#0073aa",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you! Your message has been sent successfully. A confirmation email has also been dispatched.",
						fields: [
							{ id: "f_name", type: "text", label: "Full Name", placeholder: "e.g. Sarah Connor", required: true, width: "50", subtext: "" },
							{ id: "f_email", type: "email", label: "Email Address", placeholder: "sarah@example.com", required: true, width: "50", subtext: "We will send your reply here." },
							{ id: "f_phone", type: "phone", label: "Phone Number", placeholder: "(509) 555-0199", required: false, width: "50", subtext: "Optional for SMS updates" },
							{ id: "f_dept", type: "select", label: "Department / Topic", required: true, width: "50", options: ["General Administration", "Planning & Building", "Public Works & Roads", "Natural Resources", "County Commissioners"] },
							{ id: "f_subject", type: "text", label: "Subject", placeholder: "Brief summary of your inquiry", required: true, width: "100", subtext: "" },
							{ id: "f_msg", type: "textarea", label: "Detailed Message", placeholder: "Describe your question, request, or comment in detail...", required: true, width: "100", rows: 4, subtext: "" }
						]
					},
					survey: {
						title: "Chelan County Resident Satisfaction Survey",
						description: "Help us improve local government programs and services. This survey takes approximately 2 minutes.",
						submitText: "Submit Feedback",
						themeColor: "#27ae60",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you for sharing your feedback! Your ratings help shape our community programs.",
						fields: [
							{ id: "s_dept", type: "select", label: "Which department or facility did you visit?", required: true, width: "100", options: ["County Courthouse", "Public Records Office", "Community Development / Permitting", "Sheriff's Office", "County Parks & Recreation", "Online Website Services"] },
							{ id: "s_rating", type: "rating", label: "Overall Satisfaction with Service", required: true, width: "100", subtext: "1 Star = Poor, 5 Stars = Exceptional" },
							{ id: "s_timely", type: "radio", label: "Was your request handled in a timely manner?", required: true, width: "100", options: ["Yes, very quickly", "Acceptable timeframe", "Took longer than expected", "Not resolved"] },
							{ id: "s_staff", type: "rating", label: "Staff Courtesy and Helpfulness", required: false, width: "100", subtext: "Rate your interaction with our staff" },
							{ id: "s_comments", type: "textarea", label: "Additional Suggestions or Comments", placeholder: "What went well? How could we do better?", required: false, width: "100", rows: 4, subtext: "" },
							{ id: "s_followup", type: "switch", label: "Would you like a supervisor to follow up with you?", required: false, width: "100", subtext: "If yes, please provide your contact info below." },
							{ id: "s_email", type: "email", label: "Your Email Address (optional)", placeholder: "resident@example.com", required: false, width: "100", subtext: "" }
						]
					},
					permit: {
						title: "Online Permit & Planning Inquiry",
						description: "Chelan County Community Development & Building Department online intake form.",
						submitText: "Submit Permit Inquiry",
						themeColor: "#e67e22",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Your permit inquiry has been submitted. A planner will review your parcel details and contact you.",
						fields: [
							{ id: "p_name", type: "text", label: "Applicant / Property Owner Name", placeholder: "John & Mary Smith", required: true, width: "50", subtext: "" },
							{ id: "p_phone", type: "phone", label: "Contact Phone", placeholder: "(509) 667-6225", required: true, width: "50", subtext: "" },
							{ id: "p_email", type: "email", label: "Email Address", placeholder: "applicant@example.com", required: true, width: "100", subtext: "" },
							{ id: "p_parcel", type: "text", label: "Assessor Parcel Number (APN)", placeholder: "e.g. 242010123456", required: true, width: "50", subtext: "12-digit parcel ID from tax statement" },
							{ id: "p_type", type: "select", label: "Permit / Inquiry Type", required: true, width: "50", options: ["Residential Building Permit", "Commercial Construction", "Boundary Line Adjustment", "Short Plat Subdivision", "Shoreline Exemption / Variance", "Code Compliance Question"] },
							{ id: "p_address", type: "address", label: "Project Site Address", required: true, width: "100", subtext: "Location where work will occur" },
							{ id: "p_desc", type: "textarea", label: "Description of Proposed Project", placeholder: "Include building dimensions, square footage, existing structures, and intended use...", required: true, width: "100", rows: 4, subtext: "" },
							{ id: "p_docs", type: "file", label: "Upload Site Plan / Supporting Documents", required: false, width: "100", subtext: "PDF, DOCX, or JPG (max 25MB)" },
							{ id: "p_sig", type: "signature", label: "Applicant Electronic Signature", required: true, width: "100", subtext: "By signing, you certify you are authorized to submit this inquiry." }
						]
					},
					event: {
						title: "Community Workshop & Event RSVP",
						description: "Reserve your seat for upcoming Chelan County public hearings, workshops, and informational sessions.",
						submitText: "Confirm Registration",
						themeColor: "#8e44ad",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Registration confirmed! A calendar invite and venue directions have been sent to your email.",
						fields: [
							{ id: "e_name", type: "text", label: "Attendee Full Name", placeholder: "Jane Resident", required: true, width: "50", subtext: "" },
							{ id: "e_email", type: "email", label: "Email Address", placeholder: "jane@domain.com", required: true, width: "50", subtext: "" },
							{ id: "e_session", type: "select", label: "Select Workshop Session", required: true, width: "100", options: ["2026 Comprehensive Plan - Oct 15 (Wenatchee)", "Lake Chelan Basin Water Quality - Oct 22 (Chelan)", "Wildfire Preparedness Town Hall - Nov 5 (Leavenworth)"] },
							{ id: "e_guests", type: "number", label: "Number of Attendees in Your Party", placeholder: "1", required: true, width: "50", subtext: "Including yourself (max 5)" },
							{ id: "e_accommodations", type: "checkbox", label: "Accessibility Accommodations Needed", required: false, width: "50", options: ["Wheelchair Access", "ASL Interpreter", "Spanish Translation", "Assistive Listening Device"] },
							{ id: "e_agree", type: "switch", label: "Subscribe to county planning email announcements", required: false, width: "100", subtext: "" }
						]
					},
					hrm: {
						title: "Chelan County Employment Application & Candidate Intake",
						description: "Human Resource Management (HRM) official online employment application. Chelan County is an Equal Opportunity Employer (EOE).",
						submitText: "Submit Employment Application",
						themeColor: "#8e44ad",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you for applying with Chelan County! Your application has been received by HRM and is queued for recruiter review.",
						fields: [
							{ id: "h_intro", type: "paragraph", label: "Equal Employment Opportunity Statement", content: "Chelan County provides equal employment opportunities to all employees and applicants without regard to race, color, religion, sex, national origin, age, disability, or genetics. Reasonable accommodations are provided upon request in accordance with the ADA.", paragraphStyle: "callout", width: "100" },
							{ id: "h_position", type: "select", label: "Position Applied For", required: true, width: "100", options: ["Administrative Assistant - Commissioners Office", "Planner I / II - Community Development", "Maintenance Technician - Public Works", "IT Systems Analyst - Information Technology", "Appraiser I - County Assessor", "Correctional Deputy - Sheriff Office"] },
							{ id: "h_name", type: "text", label: "Full Legal Name", placeholder: "First Middle Last", required: true, width: "50" },
							{ id: "h_email", type: "email", label: "Email Address", placeholder: "candidate@example.com", required: true, width: "50", subtext: "Official recruitment correspondence will be sent here." },
							{ id: "h_phone", type: "phone", label: "Phone Number", placeholder: "(509) 555-0123", required: true, width: "50", subtext: "Cell or best daytime phone" },
							{ id: "h_address", type: "address", label: "Current Physical / Mailing Address", required: true, width: "100" },
							{ id: "h_auth", type: "radio", label: "Are you legally authorized to work in the United States?", required: true, width: "100", options: ["Yes, I am a US citizen or permanent legal resident", "Yes, authorized with work visa/sponsorship", "No"] },
							{ id: "h_education", type: "select", label: "Highest Level of Education Completed", required: true, width: "50", options: ["High School Diploma or GED", "Associate Degree (AA/AS)", "Bachelor's Degree (BA/BS)", "Master's Degree (MA/MS)", "Doctorate / Professional Degree (JD/PhD)", "Trade / Vocational Certification"] },
							{ id: "h_veteran", type: "radio", label: "Military Veteran Status (for Veteran's Scoring Preference)", required: false, width: "50", options: ["Not a Veteran", "Honorably Discharged Veteran (eligible for RCW preference)", "Active Reserve / National Guard"] },
							{ id: "h_experience", type: "textarea", label: "Summary of Relevant Work Experience & Qualifications", placeholder: "Highlight your key positions, responsibilities, and relevant software skills...", required: true, rows: 5, width: "100", subtext: "You may also paste text from your cover letter." },
							{ id: "h_resume", type: "file", label: "Upload Resume / Curriculum Vitae", required: true, width: "50", subtext: "PDF or DOCX format (max 20MB)" },
							{ id: "h_cover", type: "file", label: "Upload Cover Letter (optional)", required: false, width: "50", subtext: "PDF or DOCX format (max 20MB)" },
							{ id: "h_affirm", type: "paragraph", label: "Applicant Certification & Authorization", content: "I hereby certify that all information submitted in this application is true and complete. I understand that false or misleading statements or omissions may result in disqualification or dismissal. I authorize Chelan County HRM to verify all credentials.", paragraphStyle: "legal", width: "100" },
							{ id: "h_signature", type: "signature", label: "Applicant Electronic Signature", required: true, width: "100", subtext: "Draw signature above with mouse or touch screen. Date will be recorded automatically." }
						]
					},
					pio: {
						title: "Public Information Office (PIO) - Media & Press Inquiry Form",
						description: "Official intake portal for journalists, reporters, and media outlets requesting county statements, records, interview access, or background information.",
						submitText: "Submit Media Inquiry",
						themeColor: "#0284c7",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Your media inquiry has been received by the Chelan County Public Information Office (PIO). A communications officer has been notified of your deadline.",
						fields: [
							{ id: "m_intro", type: "paragraph", label: "PIO Media Guidelines", content: "The Chelan County Public Information Office facilitates transparent communication with local, regional, and national press. Urgent breaking-news requests are prioritized according to deadline urgency.", paragraphStyle: "callout", width: "100" },
							{ id: "m_outlet", type: "text", label: "News Organization / Media Outlet", placeholder: "e.g. Wenatchee World, NCW Life, Seattle Times, KOHO", required: true, width: "50" },
							{ id: "m_medium", type: "select", label: "Media Type", required: true, width: "50", options: ["Print Newspaper / Magazine", "Television Broadcast News", "Radio / Audio Broadcast", "Digital News Website / Blog", "Podcast / Documentary", "Freelance / Independent"] },
							{ id: "m_reporter", type: "text", label: "Reporter / Journalist Full Name", placeholder: "e.g. Jane Doe", required: true, width: "50" },
							{ id: "m_email", type: "email", label: "Reporter Email Address", placeholder: "reporter@outlet.com", required: true, width: "50", subtext: "Written statements will be sent here." },
							{ id: "m_phone", type: "phone", label: "Direct Phone Number", placeholder: "(509) 555-0188", required: true, width: "50", subtext: "Best phone for callback" },
							{ id: "m_deadline", type: "date", label: "Publication / Broadcast Deadline Date", required: true, width: "50", subtext: "When do you need the information by?" },
							{ id: "m_nature", type: "radio", label: "Nature of Media Request", required: true, width: "100", options: ["Written Statement / Quote from County Official", "On-Camera or Studio Interview Request", "Phone / Background Briefing", "Public Records / Document Verification", "Press Conference / Media Credential Access"] },
							{ id: "m_urgent", type: "switch", label: "Urgent Breaking News Request (Within 2 Hours)", required: false, width: "100", subtext: "Check if deadline is active breaking news requiring immediate duty PIO alert." },
							{ id: "m_questions", type: "textarea", label: "Specific Questions & Topic of Inquiry", placeholder: "Please list your specific questions, the county department or elected official involved, and any context or background...", required: true, rows: 5, width: "100" }
						]
					},
					problem: {
						title: "Report a Problem & Service Request",
						description: "Chelan County Public Works online citizen service request portal. Report road hazards, potholes, streetlighting outages, fallen trees, and drainage issues.",
						submitText: "Submit Service Request",
						themeColor: "#d97706",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you for reporting this issue. Your service request has been dispatched to the Chelan County Public Works road maintenance division.",
						fields: [
							{ id: "pr_intro", type: "paragraph", label: "Public Works Service Request", content: "Chelan County Public Works responds to road hazards, potholes, streetlighting outages, fallen trees, and stormwater drainage issues on county-maintained roadways. For life-threatening emergencies, dial 911 immediately.", paragraphStyle: "callout", width: "100" },
							{ id: "pr_category", type: "select", label: "Issue Category / Hazard Type", required: true, width: "50", options: ["Pothole / Roadway Surface Damage", "Fallen Tree / Debris in Roadway", "Traffic Sign Damaged or Missing", "Streetlight Outage / Malfunction", "Drainage / Flooding / Culvert Blockage", "Snow / Ice Road Condition Hazard", "County Park or Trail Maintenance", "Other Public Works Issue"] },
							{ id: "pr_urgency", type: "radio", label: "Urgency Level", required: true, width: "50", options: ["Low - Routine maintenance", "Medium - Action needed within 48 hours", "High - Immediate safety or road blockage hazard"] },
							{ id: "pr_location", type: "text", label: "Road Name / Nearest Milepost or Intersection", placeholder: "e.g. Chumstick Hwy & Milepost 4.5, or intersection with Eagle Creek Rd", required: true, width: "100", subtext: "Provide specific location or landmarks to assist county road crews" },
							{ id: "pr_address", type: "address", label: "Nearest Physical Address (if known)", required: false, width: "100", subtext: "Street address, city, and zip code" },
							{ id: "pr_desc", type: "textarea", label: "Detailed Description of Problem", placeholder: "Describe what you observed, direction of travel, lane affected, dimensions, etc...", required: true, rows: 4, width: "100", subtext: "" },
							{ id: "pr_photo", type: "file", label: "Upload Photo of Hazard / Site Condition", required: false, width: "100", subtext: "JPG, PNG, or HEIC (max 20MB)" },
							{ id: "pr_name", type: "text", label: "Reporter Full Name", placeholder: "Jane Resident", required: true, width: "50", subtext: "" },
							{ id: "pr_phone", type: "phone", label: "Contact Phone Number", placeholder: "(509) 555-0144", required: true, width: "50", subtext: "For crew callback if location cannot be found" },
							{ id: "pr_email", type: "email", label: "Email Address", placeholder: "jane@domain.com", required: false, width: "100", subtext: "Optional: receive ticket status updates via email" }
						]
					},
					infestation: {
						title: "Report Infestations & Noxious Weeds",
						description: "Chelan County Natural Resources & Noxious Weed Control Board intake portal. Report noxious weeds, agricultural pests, and invasive tree borers.",
						submitText: "Submit Infestation Report",
						themeColor: "#15803d",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you for submitting this report. Chelan County Natural Resources and the Noxious Weed Control Board have received your filing and will review the specimen details.",
						fields: [
							{ id: "inf_intro", type: "paragraph", label: "Noxious Weed & Pest Control Reporting", content: "Chelan County Natural Resources and the Noxious Weed Control Board partner with landowners to prevent the spread of invasive species, state-quarantined pests (Apple Maggot, Emerald Ash Borer), and Class A/B/C noxious weeds under RCW 17.10.", paragraphStyle: "callout", width: "100" },
							{ id: "inf_target", type: "select", label: "Suspected Weed, Pest, or Disease", required: true, width: "100", options: ["Puncturevine (Goathead)", "Knapweed (Diffuse / Spotted / Russian)", "Scotch Broom", "Purple Loosestrife", "Rush Skeletonweed", "Yellow Starthistle", "Apple Maggot (Rhagoletis pomonella)", "Tree Borer / Invasive Bark Beetle", "Unknown Weed / Invasive Species"] },
							{ id: "inf_landtype", type: "radio", label: "Land Ownership / Property Type", required: true, width: "100", options: ["Private Landowner / Residential Property", "Commercial Orchard / Agriculture", "County Right-of-Way / Roadside", "Public Trail / Recreational Land", "USFS / BLM / State Public Land", "Unsure / Unknown"] },
							{ id: "inf_parcel", type: "text", label: "County Assessor Parcel Number (APN) if known", placeholder: "e.g. 242010123456", required: false, width: "50", subtext: "12-digit parcel number from Chelan County Assessor" },
							{ id: "inf_gps", type: "text", label: "GPS Coordinates or Nearest Milepost", placeholder: "e.g. 47.4235 N, -120.3103 W or Hwy 2 MP 108", required: true, width: "50", subtext: "Latitude/longitude or highway milepost" },
							{ id: "inf_location", type: "address", label: "Property / Site Address", required: true, width: "100", subtext: "Physical address of property where infestation was observed" },
							{ id: "inf_extent", type: "radio", label: "Estimated Area / Extent of Infestation", required: true, width: "100", options: ["Isolated single plant or few specimens (< 10 sq ft)", "Patch or cluster (10 to 500 sq ft)", "Widespread across acreage (> 1/2 acre)", "Dense infestation across multi-acre boundary"] },
							{ id: "inf_photo", type: "file", label: "Upload Specimen Photo (Flowers, Leaves, Pest)", required: false, width: "100", subtext: "Close-up photo helps our weed board coordinator identify species (max 20MB)" },
							{ id: "inf_name", type: "text", label: "Reporter Full Name", placeholder: "John Appleseed", required: true, width: "50", subtext: "" },
							{ id: "inf_phone", type: "phone", label: "Daytime Phone Number", placeholder: "(509) 667-6436", required: true, width: "50", subtext: "" },
							{ id: "inf_email", type: "email", label: "Email Address", placeholder: "landowner@appleorchard.com", required: true, width: "100", subtext: "Inspection findings and treatment recommendations will be emailed to you." }
						]
					}
				};

				let activeForm = null;
				<cfif StructKeyExists(variables, "fbPublicFormJson") and Len(Trim(variables.fbPublicFormJson)) and variables.fbPublicFormJson neq "{}">
				try {
					const dbForm = <cfoutput>#variables.fbPublicFormJson#</cfoutput>;
					if (dbForm && typeof dbForm === "object" && Object.keys(dbForm).length > 0) {
						activeForm = dbForm;
					}
				} catch(err) {}
				</cfif>

				if (!activeForm) {
					const urlParams = new URLSearchParams(window.location.search);
					const templateParam = urlParams.get("template");

					if (templateParam && TEMPLATE_PRESETS[templateParam]) {
						activeForm = TEMPLATE_PRESETS[templateParam];
					} else {
						try {
							const saved = localStorage.getItem("cmsadmin_active_form");
							if (saved) activeForm = JSON.parse(saved);
						} catch(e) {}
					}
				}

				if (!activeForm) {
					activeForm = {
						title: "Online Inquiry & Service Request",
						description: "Please complete the details below to submit your request to Chelan County.",
						submitText: "Submit Request",
						themeColor: "#0073aa",
						minDelaySeconds: 3,
						cooldownSeconds: 3,
						antiSpamEnabled: true,
						successMessage: "Thank you! Your request has been recorded.",
						fields: [
							{ id: "f1", type: "text", label: "Full Name", required: true, placeholder: "Sarah Connor" },
							{ id: "f2", type: "email", label: "Email Address", required: true, placeholder: "sarah@example.com" },
							{ id: "f3", type: "textarea", label: "Message / Description", required: true, rows: 4, placeholder: "Describe your inquiry in detail..." }
						]
					};
				}

				const minDelay = activeForm.minDelaySeconds !== undefined ? activeForm.minDelaySeconds : 3;
				const cooldown = activeForm.cooldownSeconds !== undefined ? activeForm.cooldownSeconds : 3;

				document.getElementById("formTitle").innerText = activeForm.title;
				document.getElementById("formDesc").innerText = activeForm.description || "";
				document.getElementById("btnSubmit").innerText = activeForm.submitText || "Submit Form";

				// Populate form identity hidden inputs so /forms/submit persists to DB & dispatches emails
				const pageUrlParams = new URLSearchParams(window.location.search);
				const resolvedFormId = activeForm.dbId || (typeof activeForm.id === "number" ? activeForm.id : (String(activeForm.id || "").replace(/^form_/, ""))) || pageUrlParams.get("id") || "";
				const resolvedFormKey = activeForm.formKey || activeForm.key || pageUrlParams.get("key") || "";
				const resolvedFormSlug = activeForm.slug || pageUrlParams.get("slug") || "";
				if (document.getElementById("_form_id")) document.getElementById("_form_id").value = resolvedFormId;
				if (document.getElementById("_form_key")) document.getElementById("_form_key").value = resolvedFormKey;
				if (document.getElementById("_form_slug")) document.getElementById("_form_slug").value = resolvedFormSlug;

				if (activeForm.themeColor) {
					document.documentElement.style.setProperty("--primary", activeForm.themeColor);
				}

				const container = document.getElementById("dynamicFields");
				container.innerHTML = "";

				(activeForm.fields || []).forEach(f => {
					const req = f.required ? 'required aria-required="true"' : "";
					const star = f.required ? '<span class="required-star" aria-hidden="true">*</span><span class="sr-only"> (required)</span>' : "";
					const descId = f.subtext ? 'desc_' + f.id : '';
					const ariaDesc = descId ? 'aria-describedby="' + descId + '"' : '';
					const sub = f.subtext ? '<div id="' + descId + '" class="field-subtext">' + escapeHTML(f.subtext) + '</div>' : "";
					const isMobile = window.innerWidth <= 768;
					const configuredWidth = f.width || "100";
					const colClass = (isMobile && (configuredWidth === "50" || configuredWidth === "33"))
						? "field-col-100"
						: (configuredWidth === "50" ? "field-col-50" : (configuredWidth === "33" ? "field-col-33" : "field-col-100"));

					const div = document.createElement("div");
					div.className = "field-group " + colClass;
					div.setAttribute("data-desktop-col", configuredWidth);

					if (f.type === "textarea") {
						div.innerHTML = `
							<label for="field_${f.id}" class="field-label">${escapeHTML(f.label)} ${star}</label>
							<textarea id="field_${f.id}" class="form-control" name="${f.id}" rows="${f.rows || 4}" placeholder="${escapeHTML(f.placeholder || "")}" ${req} ${ariaDesc}></textarea>
							${sub}
						`;
					} else if (f.type === "paragraph") {
						div.innerHTML = `
							<div class="form-paragraph-block ${f.paragraphStyle ? 'style-' + f.paragraphStyle : ''}" style="width:100%;">
								<p class="form-paragraph-text">${escapeHTML(f.content || f.label || "")}</p>
							</div>
							${sub}
						`;
					} else if (f.type === "select") {
						const opts = (f.options || []).map(o => `<option value="${escapeHTML(o)}">${escapeHTML(o)}</option>`).join("");
						div.innerHTML = `
							<label for="field_${f.id}" class="field-label">${escapeHTML(f.label)} ${star}</label>
							<select id="field_${f.id}" class="form-control" name="${f.id}" ${req} ${ariaDesc}>
								<option value="">-- Please Select --</option>
								${opts}
							</select>
							${sub}
						`;
					} else if (f.type === "radio") {
						const opts = (f.options || []).map((o, idx) => `
							<label class="form-option-item">
								<input type="radio" id="rad_${f.id}_${idx}" name="${f.id}" value="${escapeHTML(o)}" ${f.required ? 'required aria-required="true"' : ""}>
								<span>${escapeHTML(o)}</span>
							</label>
						`).join("");
						div.innerHTML = `
							<fieldset class="form-fieldset" role="radiogroup" ${ariaDesc}>
								<legend class="form-legend">${escapeHTML(f.label)} ${star}</legend>
								<div class="form-options-wrap">${opts}</div>
								${sub}
							</fieldset>
						`;
					} else if (f.type === "checkbox") {
						const opts = (f.options || []).map((o, idx) => `
							<label class="form-option-item">
								<input type="checkbox" id="chk_${f.id}_${idx}" name="${f.id}[]" value="${escapeHTML(o)}">
								<span>${escapeHTML(o)}</span>
							</label>
						`).join("");
						div.innerHTML = `
							<fieldset class="form-fieldset" role="group" ${ariaDesc}>
								<legend class="form-legend">${escapeHTML(f.label)} ${star}</legend>
								<div class="form-options-wrap">${opts}</div>
								${sub}
							</fieldset>
						`;
					} else if (f.type === "address") {
						div.innerHTML = `
							<fieldset class="form-fieldset form-address-group" role="group" ${ariaDesc}>
								<legend class="form-legend">${escapeHTML(f.label)} ${star}</legend>
								<div class="form-address-fields">
									<input type="text" id="field_${f.id}_street" name="${f.id}_street" class="form-control" placeholder="Street Address (e.g. 350 Orondo Ave)" aria-label="Street Address" ${req}>
									<input type="text" id="field_${f.id}_street2" name="${f.id}_street2" class="form-control" placeholder="Apt, Suite, Unit, Building (Optional)" aria-label="Address Line 2">
									<div class="form-address-row-city-state-zip">
										<input type="text" id="field_${f.id}_city" name="${f.id}_city" class="form-control form-address-col-city" placeholder="City (e.g. Wenatchee)" aria-label="City" ${req}>
										<input type="text" id="field_${f.id}_state" name="${f.id}_state" class="form-control form-address-col-state" value="${escapeHTML(f.defaultState || "WA")}" aria-label="State" ${req}>
										<input type="text" id="field_${f.id}_zip" name="${f.id}_zip" class="form-control form-address-col-zip" placeholder="ZIP Code (e.g. 98801)" aria-label="ZIP Code" ${req}>
									</div>
								</div>
								${sub}
							</fieldset>
						`;
					} else if (f.type === "switch") {
						div.innerHTML = `
							<div class="form-switch-row">
								<div>
									<label for="field_${f.id}" class="field-label" style="margin-bottom:0; cursor:pointer;">${escapeHTML(f.label)} ${star}</label>
									${sub}
								</div>
								<input type="checkbox" id="field_${f.id}" name="${f.id}" style="width:20px; height:20px; accent-color:var(--primary); cursor:pointer;" ${req}>
							</div>
						`;
					} else if (f.type === "file") {
						div.innerHTML = `
							<label for="field_${f.id}" class="field-label">${escapeHTML(f.label)} ${star}</label>
							<input type="file" id="field_${f.id}" name="${f.id}" class="form-control" style="border-style:dashed; background:var(--bg);" ${req} ${ariaDesc}>
							${sub}
						`;
					} else if (f.type === "signature") {
						div.innerHTML = `
							<label for="field_${f.id}" class="field-label">${escapeHTML(f.label)} ${star}</label>
							<div class="form-signature-box">
								<input type="text" id="field_${f.id}" name="${f.id}" class="form-signature-input" placeholder="Type your full legal name to digitally sign" ${req} ${ariaDesc}>
							</div>
							<div style="font-size:0.75rem; color:var(--text-muted); margin-top:0.25rem;">Accessible Digital Signature Capture &bull; Legally Binding</div>
							${sub}
						`;
					} else if (f.type === "rating") {
						div.innerHTML = `
							<label class="field-label">${escapeHTML(f.label)} ${star}</label>
							<div class="interactive-star-rating" role="radiogroup" aria-label="${escapeHTML(f.label)}" data-field="${f.id}">
								${[1, 2, 3, 4, 5].map((star) => `
									<button type="button" class="star-btn" data-value="${star}" role="radio" aria-checked="${star === 5 ? "true" : "false"}" aria-label="${star} out of 5 stars">&#9733;</button>
								`).join("")}
								<input type="hidden" name="${f.id}" value="5" ${req}>
							</div>
							${sub}
						`;
					} else if (f.type === "heading") {
						div.innerHTML = `
							<div style="padding-top:0.75rem; border-top:1px solid var(--border-subtle); width:100%;">
								<h2 style="margin:0 0 0.25rem 0; font-size:1.25rem; color:var(--text);">${escapeHTML(f.label)}</h2>
								${f.subtext ? `<p class="field-subtext" style="margin:0;">${escapeHTML(f.subtext)}</p>` : ''}
							</div>
						`;
					} else if (f.type === "divider") {
						div.innerHTML = `<hr style="border:none; border-top:1px dashed var(--border); margin:0.5rem 0; width:100%;" role="separator">`;
					} else {
						const inputType = f.type === "email" ? "email" : ((f.type === "phone" || f.type === "tel") ? "tel" : (f.type === "number" ? "number" : (f.type === "date" ? "date" : "text")));
						const autoComp = f.type === "email" ? 'autocomplete="email"' : ((f.type === "phone" || f.type === "tel") ? 'autocomplete="tel"' : '');
						div.innerHTML = `
							<label for="field_${f.id}" class="field-label">${escapeHTML(f.label)} ${star}</label>
							<input type="${inputType}" id="field_${f.id}" class="form-control" name="${f.id}" placeholder="${escapeHTML(f.placeholder || "")}" ${autoComp} ${req} ${ariaDesc}>
							${sub}
						`;
					}
					container.appendChild(div);
				});

				// Initialize interactive star ratings
				container.querySelectorAll(".interactive-star-rating").forEach(wrap => {
					const stars = wrap.querySelectorAll(".star-btn");
					const hiddenInput = wrap.querySelector("input");
					const updateStars = (val) => {
						stars.forEach((s, idx) => {
							s.style.color = idx < val ? "var(--warning)" : "#cbd5e1";
							s.setAttribute("aria-checked", idx + 1 === val ? "true" : "false");
						});
						hiddenInput.value = val;
					};
					updateStars(5);
					stars.forEach(star => {
						star.addEventListener("click", () => {
							updateStars(parseInt(star.getAttribute("data-value"), 10));
						});
					});
				});

				// Form submission with anti-spam honeypot & speed trap enforcement
				const form = document.getElementById("publicForm");
				form.addEventListener("submit", function(e) {
					e.preventDefault();
					const alertEl = document.getElementById("formAlertBanner");
					const btn = document.getElementById("btnSubmit");

					// 0. Native HTML5 Accessibility Validation
					if (!form.checkValidity()) {
						form.reportValidity();
						return;
					}

					// 0b. Block empty form submissions (ensure at least one field has meaningful user input)
					let hasMeaningfulInput = false;
					let firstFocusableInput = null;
					(activeForm.fields || []).forEach(f => {
						if (!f || !f.id || ["paragraph", "heading", "divider", "section", "html"].includes(f.type)) return;
						if (f.type === "address") {
							const stEl = document.getElementById(`field_${f.id}_street`);
							const st2El = document.getElementById(`field_${f.id}_street2`);
							const cityEl = document.getElementById(`field_${f.id}_city`);
							const zipEl = document.getElementById(`field_${f.id}_zip`);
							if (!firstFocusableInput && stEl) firstFocusableInput = stEl;
							if ((stEl && stEl.value.trim() !== "") || (st2El && st2El.value.trim() !== "") || (cityEl && cityEl.value.trim() !== "") || (zipEl && zipEl.value.trim() !== "")) {
								hasMeaningfulInput = true;
							}
						} else if (f.type === "checkbox") {
							const firstChk = form.querySelector(`input[name="${f.id}[]"]`);
							if (!firstFocusableInput && firstChk) firstFocusableInput = firstChk;
							if (form.querySelectorAll(`input[name="${f.id}[]"]:checked`).length > 0) {
								hasMeaningfulInput = true;
							}
						} else if (f.type === "radio") {
							const firstRad = form.querySelector(`input[name="${f.id}"]`);
							if (!firstFocusableInput && firstRad) firstFocusableInput = firstRad;
							if (form.querySelector(`input[name="${f.id}"]:checked`)) {
								hasMeaningfulInput = true;
							}
						} else if (f.type === "switch") {
							const sw = document.getElementById(`field_${f.id}`);
							if (sw && sw.checked) {
								hasMeaningfulInput = true;
							}
						} else if (f.type === "file") {
							const fileEl = document.getElementById(`field_${f.id}`);
							if (!firstFocusableInput && fileEl) firstFocusableInput = fileEl;
							if (fileEl && fileEl.files && fileEl.files.length > 0) {
								hasMeaningfulInput = true;
							}
						} else {
							const el = document.getElementById(`field_${f.id}`) || form.querySelector(`[name="${f.id}"]`);
							if (!firstFocusableInput && el) firstFocusableInput = el;
							if (el && el.value.trim() !== "") {
								hasMeaningfulInput = true;
							}
						}
					});

					if (!hasMeaningfulInput) {
						alertEl.className = "alert-banner error";
						alertEl.innerHTML = "<strong>Empty Form Cannot Be Submitted:</strong> Please fill in the form fields before submitting.";
						alertEl.style.display = "flex";
						alertEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
						if (firstFocusableInput && typeof firstFocusableInput.focus === "function") {
							firstFocusableInput.focus();
						}
						sendHeightToParent();
						return;
					}

					// 1. Anti-Spam Check: Honeypot trap
					const hpVal = document.getElementById("_chelan_gov_verify").value.trim();
					if (hpVal !== "") {
						alertEl.className = "alert-banner error";
						alertEl.innerHTML = "<strong>Security Verification Failed:</strong> Automated bot submission detected. Form blocked.";
						alertEl.style.display = "flex";
						alertEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
						return;
					}

					// 2. Anti-Spam Check: Submission Speed Trap (Minimum Time Delay)
					const loadTime = parseInt(document.getElementById("_cf_form_load_time").value, 10);
					const elapsed = (Date.now() - loadTime) / 1000;
					if (activeForm.antiSpamEnabled !== false && minDelay > 0 && elapsed < minDelay) {
						const remaining = Math.ceil(minDelay - elapsed);
						alertEl.className = "alert-banner warning";
						alertEl.innerHTML = `
							<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="flex-shrink:0;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
							<div>
								<strong>Submission Delay Active (Anti-Spam Security):</strong>
								Please review your information before submitting. To safeguard against automated form spamming, submissions require a minimum ${minDelay}-second review time. Please wait <strong>${remaining} second(s)</strong> and submit again.
							</div>
						`;
						alertEl.style.display = "flex";
						alertEl.scrollIntoView({ behavior: "smooth", block: "nearest" });
						return;
					}

					// 3. Clear alert and start submit cooldown
					alertEl.style.display = "none";
					btn.disabled = true;
					btn.classList.add("btn-submitting");
					btn.innerText = "Verifying security & submitting...";

					// Submit to server endpoint /forms/submit
					const formData = new FormData(form);
					if (resolvedFormId) formData.set("_form_id", String(resolvedFormId));
					if (resolvedFormKey) formData.set("_form_key", String(resolvedFormKey));
					if (resolvedFormSlug) formData.set("_form_slug", String(resolvedFormSlug));

					// Build structured field payload (normalizing multi-part address blocks, checkbox groups, and switches)
					const payloadObj = {};
					(activeForm.fields || []).forEach(f => {
						if (!f || !f.id || ["paragraph", "heading", "divider", "section", "html", "file"].includes(f.type)) return;
						if (f.type === "address") {
							const stEl = document.getElementById(`field_${f.id}_street`);
							const st2El = document.getElementById(`field_${f.id}_street2`);
							const cityEl = document.getElementById(`field_${f.id}_city`);
							const stateEl = document.getElementById(`field_${f.id}_state`);
							const zipEl = document.getElementById(`field_${f.id}_zip`);
							payloadObj[f.id] = {
								street: stEl ? stEl.value.trim() : "",
								street2: st2El ? st2El.value.trim() : "",
								city: cityEl ? cityEl.value.trim() : "",
								state: stateEl ? stateEl.value.trim() : "",
								zip: zipEl ? zipEl.value.trim() : ""
							};
						} else if (f.type === "checkbox") {
							const checked = [];
							form.querySelectorAll(`input[name="${f.id}[]"]:checked`).forEach(chk => checked.push(chk.value));
							payloadObj[f.id] = checked;
						} else if (f.type === "radio") {
							const r = form.querySelector(`input[name="${f.id}"]:checked`);
							payloadObj[f.id] = r ? r.value : "";
						} else if (f.type === "switch") {
							const sw = document.getElementById(`field_${f.id}`);
							payloadObj[f.id] = sw && sw.checked ? "Yes" : "No";
						} else {
							const el = document.getElementById(`field_${f.id}`) || form.querySelector(`[name="${f.id}"]`);
							payloadObj[f.id] = el ? el.value.trim() : "";
						}
					});
					formData.set("_payload", JSON.stringify(payloadObj));

					fetch("/forms/submit", {
						method: "POST",
						body: formData
					})
					.then(res => res.json())
					.then(data => {
						if (data.success) {
							if (data.redirectUrl && String(data.redirectUrl).trim().length > 0) {
								window.top.location.href = String(data.redirectUrl).trim();
								return;
							}
							showSuccess(data.referenceId || ("SUB-" + Math.floor(100000 + Math.random() * 900000)));
						} else {
							alertEl.className = "alert-banner error";
							alertEl.innerHTML = "<strong>Submission Error:</strong> " + (data.message || "An error occurred during submission.");
							alertEl.style.display = "flex";
							btn.disabled = false;
							btn.classList.remove("btn-submitting");
							btn.innerText = activeForm.submitText || "Submit Form";
						}
					})
					.catch((err) => {
						if (resolvedFormId || resolvedFormKey || resolvedFormSlug) {
							alertEl.className = "alert-banner error";
							alertEl.innerHTML = "<strong>Submission Error:</strong> Unable to reach the server to record your submission. Please try again.";
							alertEl.style.display = "flex";
							btn.disabled = false;
							btn.classList.remove("btn-submitting");
							btn.innerText = activeForm.submitText || "Submit Form";
							return;
						}
						// Simulated fallback only for unsaved template demos
						setTimeout(() => {
							showSuccess("SUB-" + Math.floor(100000 + Math.random() * 900000));
						}, 1200);
					});

					function showSuccess(refId) {
						document.getElementById("formCard").style.display = "none";
						document.getElementById("successMsg").innerText = activeForm.successMessage || "Thank you! Your submission has been received by Chelan County.";
						document.getElementById("metaRefId").innerText = refId;
						document.getElementById("metaTime").innerText = new Date().toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", second: "2-digit" });
						document.getElementById("successCard").style.display = "block";
						
						const heading = document.getElementById("successHeading");
						if (heading) heading.focus();
						sendHeightToParent();
					}
				});

				// Window resize listener to automatically toggle column classes on mobile viewports
				window.addEventListener("resize", () => {
					const isMobile = window.innerWidth <= 768;
					document.querySelectorAll(".form-body .field-group").forEach((div) => {
						const origWidth = div.getAttribute("data-desktop-col") || "100";
						if (origWidth === "50" || origWidth === "33") {
							if (isMobile) {
								div.classList.remove("field-col-50", "field-col-33");
								div.classList.add("field-col-100");
							} else {
								div.classList.remove("field-col-100");
								div.classList.add(origWidth === "50" ? "field-col-50" : "field-col-33");
							}
						}
					});
					sendHeightToParent();
				});

				function escapeHTML(str) {
					if (!str) return "";
					return String(str)
						.replace(/&/g, "&amp;")
						.replace(/</g, "&lt;")
						.replace(/>/g, "&gt;")
						.replace(/"/g, "&quot;")
						.replace(/'/g, "&#039;");
				}

				// Auto-emit height upon initial load and window resizing
				sendHeightToParent();
				setTimeout(function() { sendHeightToParent(true); }, 80);
				setTimeout(function() { sendHeightToParent(true); }, 250);
				setTimeout(function() { sendHeightToParent(true); }, 600);
				setTimeout(function() { sendHeightToParent(true); }, 1200);
				window.addEventListener("load", function() { sendHeightToParent(true); });
				if (document.fonts && document.fonts.ready) {
					document.fonts.ready.then(function() { sendHeightToParent(true); });
				}

				if (window.ResizeObserver) {
					var ro = new ResizeObserver(function() {
						sendHeightToParent();
					});
					var wrapEl = document.querySelector(".form-wrapper");
					if (wrapEl) ro.observe(wrapEl);
					var cardEl = document.getElementById("formCard");
					if (cardEl) ro.observe(cardEl);
				}

				window.addEventListener("message", function(e) {
					if (e.data && (e.data.type === "chelan-form-request-height" || e.data === "chelan-form-request-height")) {
						sendHeightToParent(true);
					}
				});
			})();
		</script>
	</body>
</html>
