<cfoutput>
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>#variables.pageTitle#</title>
	#csrfMetaTags()#

	<!--- Fonts & Styles --->
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap" rel="stylesheet">
	
	<link rel="icon" type="image/png" href="/images/logo.png">
	<link rel="apple-touch-icon" href="/images/logo.png">
	<link href="/stylesheets/admin-theme.css?v=2.9" media="all" rel="stylesheet" type="text/css">

	<style>
		:root {
			--login-card-max-width: 520px;
			--login-primary: ##0073aa;
			--login-primary-dark: ##005177;
			--login-primary-light: ##eef7fc;
			--login-accent: ##0a4b78;
		}

		body.login-page-body {
			min-height: 100vh;
			margin: 0;
			padding: 2rem 1rem;
			font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
			background: linear-gradient(135deg, ##0e2439 0%, ##1a365d 40%, ##0a4b78 100%);
			background-attachment: fixed;
			display: flex;
			flex-direction: column;
			align-items: center;
			justify-content: center;
			color: ##1e293b;
			position: relative;
			overflow-x: hidden;
		}

		/* Subtle background geometric pattern */
		body.login-page-body::before {
			content: '';
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			background-image: 
				radial-gradient(circle at 15% 20%, rgba(0, 115, 170, 0.25) 0%, transparent 40%),
				radial-gradient(circle at 85% 80%, rgba(30, 64, 175, 0.25) 0%, transparent 45%);
			pointer-events: none;
		}

		.login-container {
			position: relative;
			z-index: 2;
			width: 100%;
			max-width: var(--login-card-max-width);
			margin: 0 auto;
		}

		.login-brand-header {
			text-align: center;
			margin-bottom: 1.75rem;
		}

		.login-seal {
			height: 250px;
			max-height: 250px;
			width: auto;
			max-width: 100%;
			object-fit: contain;
			display: block;
			margin-left: auto;
			margin-right: auto;
			margin-bottom: 1.25rem;
			filter: drop-shadow(0 8px 24px rgba(0, 0, 0, 0.35));
			transition: transform 0.25s ease, filter 0.25s ease;
		}

		.login-seal:hover {
			transform: scale(1.02);
			filter: drop-shadow(0 12px 28px rgba(0, 0, 0, 0.45));
		}

		.login-brand-title {
			color: ##ffffff;
			font-size: 1.5rem;
			font-weight: 800;
			letter-spacing: -0.02em;
			margin: 0 0 0.25rem 0;
			text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
		}

		.login-brand-sub {
			color: rgba(255, 255, 255, 0.8);
			font-size: 0.88rem;
			font-weight: 500;
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
		}

		.login-card {
			background: ##ffffff;
			border-radius: 16px;
			box-shadow: 0 20px 45px rgba(0, 0, 0, 0.28), 0 0 0 1px rgba(255, 255, 255, 0.1);
			padding: 2.25rem;
			position: relative;
			overflow: hidden;
		}

		.login-card::before {
			content: '';
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			height: 5px;
			background: linear-gradient(90deg, ##0073aa 0%, ##0a4b78 50%, ##00b4d8 100%);
		}

		.step-header {
			margin-bottom: 1.5rem;
		}

		.step-title {
			font-size: 1.25rem;
			font-weight: 700;
			color: ##0f172a;
			margin: 0 0 0.35rem 0;
		}

		.step-desc {
			font-size: 0.88rem;
			color: ##64748b;
			margin: 0;
			line-height: 1.45;
		}

		.form-group-custom {
			margin-bottom: 1.25rem;
		}

		.form-label-custom {
			display: block;
			font-size: 0.85rem;
			font-weight: 600;
			color: ##334155;
			margin-bottom: 0.45rem;
		}

		.input-with-icon {
			position: relative;
			display: flex;
			align-items: center;
		}

		.input-icon-left {
			position: absolute;
			left: 1rem;
			color: ##94a3b8;
			pointer-events: none;
			display: flex;
			align-items: center;
		}

		.form-control-custom {
			width: 100%;
			padding: 0.85rem 1rem 0.85rem 2.75rem;
			font-size: 0.95rem;
			font-family: inherit;
			color: ##0f172a;
			background: ##f8fafc;
			border: 1.5px solid ##cbd5e1;
			border-radius: 10px;
			transition: all 0.15s ease;
			box-sizing: border-box;
		}

		.form-control-custom:focus {
			outline: none;
			background: ##ffffff;
			border-color: var(--login-primary);
			box-shadow: 0 0 0 3.5px rgba(0, 115, 170, 0.18);
		}

		.btn-login-primary {
			width: 100%;
			padding: 0.85rem 1.25rem;
			font-size: 0.95rem;
			font-weight: 700;
			font-family: inherit;
			color: ##ffffff;
			background: var(--login-primary);
			border: none;
			border-radius: 10px;
			cursor: pointer;
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.5rem;
			transition: all 0.15s ease;
			box-shadow: 0 4px 12px rgba(0, 115, 170, 0.3);
		}

		.btn-login-primary:hover:not(:disabled) {
			background: var(--login-primary-dark);
			box-shadow: 0 6px 16px rgba(0, 115, 170, 0.4);
			transform: translateY(-1px);
		}

		.btn-login-primary:active:not(:disabled) {
			transform: translateY(0);
		}

		.btn-login-primary:disabled {
			opacity: 0.65;
			cursor: not-allowed;
		}

		/* User Profile Header in Step 2 */
		.user-profile-badge-card {
			background: ##f1f5f9;
			border: 1px solid ##e2e8f0;
			border-radius: 12px;
			padding: 1rem 1.15rem;
			margin-bottom: 1.5rem;
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 1rem;
		}

		.profile-avatar-circle {
			width: 48px;
			height: 48px;
			border-radius: 50%;
			background: linear-gradient(135deg, ##0073aa, ##0a4b78);
			color: ##ffffff;
			font-weight: 800;
			font-size: 1.05rem;
			display: flex;
			align-items: center;
			justify-content: center;
			flex-shrink: 0;
			box-shadow: 0 2px 8px rgba(0, 115, 170, 0.25);
		}

		.profile-info {
			flex: 1;
			min-width: 0;
		}

		.profile-name-row {
			display: flex;
			align-items: center;
			gap: 0.5rem;
			flex-wrap: wrap;
			margin-bottom: 0.2rem;
		}

		.profile-name {
			font-weight: 700;
			font-size: 1rem;
			color: ##0f172a;
		}

		.profile-email {
			font-size: 0.82rem;
			color: ##64748b;
			word-break: break-all;
		}

		.profile-dept {
			font-size: 0.75rem;
			color: ##475569;
			font-weight: 500;
			margin-top: 0.15rem;
		}

		.btn-switch-account {
			background: transparent;
			border: 1px solid ##cbd5e1;
			padding: 0.35rem 0.65rem;
			border-radius: 6px;
			font-size: 0.75rem;
			font-weight: 600;
			color: ##475569;
			cursor: pointer;
			transition: all 0.15s ease;
			white-space: nowrap;
		}

		.btn-switch-account:hover {
			background: ##ffffff;
			border-color: ##94a3b8;
			color: ##0f172a;
		}

		/* Authentication Choice Cards */
		.auth-options-grid {
			display: flex;
			flex-direction: column;
			gap: 0.85rem;
			margin-bottom: 1.25rem;
		}

		.auth-option-card {
			background: ##ffffff;
			border: 1.5px solid ##e2e8f0;
			border-radius: 12px;
			padding: 1.15rem 1.25rem;
			cursor: pointer;
			transition: all 0.18s ease;
			display: flex;
			align-items: flex-start;
			gap: 1rem;
			text-align: left;
			width: 100%;
			box-sizing: border-box;
		}

		.auth-option-card:hover {
			border-color: var(--login-primary);
			background: ##f8fafc;
			transform: translateY(-2px);
			box-shadow: 0 4px 14px rgba(0, 115, 170, 0.12);
		}

		.auth-option-card.is-selected {
			border-color: var(--login-primary);
			background: var(--login-primary-light);
			box-shadow: 0 0 0 1px var(--login-primary);
		}

		.auth-option-icon {
			width: 40px;
			height: 40px;
			border-radius: 10px;
			background: ##f1f5f9;
			color: var(--login-primary);
			display: flex;
			align-items: center;
			justify-content: center;
			flex-shrink: 0;
			transition: all 0.15s ease;
		}

		.auth-option-card:hover .auth-option-icon,
		.auth-option-card.is-selected .auth-option-icon {
			background: var(--login-primary);
			color: ##ffffff;
		}

		.auth-option-body {
			flex: 1;
		}

		.auth-option-title {
			font-size: 0.95rem;
			font-weight: 700;
			color: ##0f172a;
			margin: 0 0 0.2rem 0;
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 0.5rem;
		}

		.auth-option-desc {
			font-size: 0.82rem;
			color: ##64748b;
			margin: 0;
			line-height: 1.4;
		}

		/* Method Interactive Panels */
		.method-panel {
			display: none;
			margin-top: 1.25rem;
			padding: 1.25rem;
			background: ##f8fafc;
			border: 1px solid ##e2e8f0;
			border-radius: 12px;
			animation: fadeIn 0.2s ease-out;
		}

		.method-panel.is-active {
			display: block;
		}

		@keyframes fadeIn {
			from { opacity: 0; transform: translateY(6px); }
			to { opacity: 1; transform: translateY(0); }
		}

		/* Bypass helper callout */
		.bypass-alert {
			background: ##eff6ff;
			border: 1px solid ##bfdbfe;
			border-radius: 8px;
			padding: 0.75rem 1rem;
			font-size: 0.82rem;
			color: ##1e40af;
			margin: 0.85rem 0;
			display: flex;
			align-items: center;
			justify-content: space-between;
			gap: 0.5rem;
		}

		.bypass-chip {
			background: ##dbeafe;
			border: 1px solid ##93c5fd;
			color: ##1e3a8a;
			font-family: monospace;
			font-weight: 800;
			padding: 0.2rem 0.55rem;
			border-radius: 4px;
			cursor: pointer;
			transition: all 0.15s ease;
			font-size: 0.85rem;
		}

		.bypass-chip:hover {
			background: ##bfdbfe;
			transform: scale(1.04);
		}

		/* Authenticator QR Code Setup Box */
		.qr-setup-box {
			background: ##ffffff;
			border: 1px solid ##e2e8f0;
			border-radius: 12px;
			padding: 1.25rem;
			text-align: center;
			margin-bottom: 1.25rem;
		}

		.qr-code-img {
			width: 170px;
			height: 170px;
			border: 1px solid ##e2e8f0;
			border-radius: 8px;
			padding: 6px;
			background: ##ffffff;
			margin: 0 auto 1rem auto;
			display: block;
			box-shadow: 0 4px 12px rgba(0, 0, 0, 0.06);
		}

		.secret-key-display {
			font-family: monospace;
			font-size: 1.1rem;
			font-weight: 800;
			letter-spacing: 0.15em;
			background: ##f1f5f9;
			padding: 0.65rem 1rem;
			border-radius: 8px;
			border: 1px solid ##cbd5e1;
			color: ##0f172a;
			display: flex;
			align-items: center;
			justify-content: center;
			gap: 0.75rem;
			margin: 0.5rem 0;
			user-select: all;
		}

		.btn-copy-secret {
			background: ##ffffff;
			border: 1px solid ##cbd5e1;
			border-radius: 6px;
			padding: 0.25rem 0.6rem;
			font-size: 0.75rem;
			font-weight: 600;
			cursor: pointer;
			transition: all 0.15s ease;
		}

		.btn-copy-secret:hover {
			background: ##f8fafc;
			border-color: ##94a3b8;
		}

		/* Sample Users Demo Pills */
		.demo-accounts-section {
			margin-top: 1.75rem;
			padding-top: 1.25rem;
			border-top: 1px dashed ##cbd5e1;
		}

		.demo-section-title {
			font-size: 0.78rem;
			font-weight: 700;
			text-transform: uppercase;
			letter-spacing: 0.05em;
			color: ##64748b;
			margin-bottom: 0.65rem;
			display: flex;
			align-items: center;
			gap: 0.4rem;
		}

		.demo-pills-list {
			display: flex;
			flex-wrap: wrap;
			gap: 0.45rem;
		}

		.demo-user-pill {
			background: ##f1f5f9;
			border: 1px solid ##cbd5e1;
			border-radius: 20px;
			padding: 0.35rem 0.75rem;
			font-size: 0.78rem;
			color: ##334155;
			cursor: pointer;
			transition: all 0.15s ease;
			display: inline-flex;
			align-items: center;
			gap: 0.4rem;
			font-weight: 500;
		}

		.demo-user-pill:hover {
			background: var(--login-primary-light);
			border-color: var(--login-primary);
			color: var(--login-primary-dark);
			transform: translateY(-1px);
		}

		.demo-role-tag {
			font-size: 0.68rem;
			padding: 0.1rem 0.4rem;
			border-radius: 10px;
			font-weight: 700;
		}

		/* Flash & Session Alerts */
		##flashAlertContainer {
			transition: opacity 0.45s ease, transform 0.45s ease, max-height 0.45s ease, margin 0.45s ease;
			overflow: hidden;
		}

		##flashAlertContainer .flash-messages {
			margin-bottom: 1.25rem;
		}

		##flashAlertContainer .alert {
			box-shadow: 0 4px 16px rgba(0, 0, 0, 0.18);
			border-radius: 12px;
		}

		/* In-Card Alerts */
		.login-alert {
			padding: 0.85rem 1.15rem;
			border-radius: 10px;
			font-size: 0.88rem;
			margin-bottom: 1.25rem;
			display: flex;
			align-items: flex-start;
			gap: 0.65rem;
			line-height: 1.45;
			border-left: 4px solid transparent;
			transition: opacity 0.45s ease, transform 0.45s ease;
		}

		.login-alert-dismiss {
			background: transparent;
			border: none;
			color: inherit;
			opacity: 0.55;
			cursor: pointer;
			padding: 0.2rem;
			display: inline-flex;
			align-items: center;
			justify-content: center;
			border-radius: 4px;
			transition: opacity 0.15s ease, background-color 0.15s ease;
			flex-shrink: 0;
			margin-left: 0.5rem;
		}

		.login-alert-dismiss:hover {
			opacity: 1;
			background: rgba(0, 0, 0, 0.08);
		}

		.login-alert-danger {
			background: ##fef2f2;
			border: 1px solid ##fecaca;
			border-left: 4px solid ##b91c1c;
			color: ##991b1b;
		}

		.login-alert-success {
			background: ##f0fdf4;
			border: 1px solid ##bbf7d0;
			border-left: 4px solid ##15803d;
			color: ##14532d;
		}

		.login-footer-info {
			text-align: center;
			margin-top: 1.75rem;
			font-size: 0.82rem;
			color: rgba(255, 255, 255, 0.75);
			line-height: 1.5;
		}

		.login-footer-info a {
			color: ##ffffff;
			text-decoration: underline;
		}

		.spinner-inline {
			display: inline-block;
			width: 16px;
			height: 16px;
			border: 2px solid rgba(255, 255, 255, 0.3);
			border-radius: 50%;
			border-top-color: ##ffffff;
			animation: spin 0.6s linear infinite;
		}

		@keyframes spin {
			to { transform: rotate(360deg); }
		}

		@media (max-width: 480px) {
			.login-seal {
				height: 180px;
				max-height: 180px;
			}
			.login-card {
				padding: 1.5rem 1.25rem;
			}
		}
	</style>
</head>

<body class="login-page-body">

	<div class="login-container">
		<!--- Chelan County Seal Header --->
		<div class="login-brand-header">
			<img src="/images/logo.png" alt="Chelan County Seal" class="login-seal" width="250" height="250">
			<h1 class="login-brand-title">Chelan County CMS</h1>
			<div class="login-brand-sub">
				<span>#svgIcon(name="lock", size=14)# Official Government Portal</span>
				<span>&bull;</span>
				<span>Authorized Access Only</span>
			</div>
		</div>

		<!--- Flash Messages Container --->
		<div id="flashAlertContainer">
			#flashMessages(encode=false)#
		</div>

		<!--- Main Interactive Login Card --->
		<div class="login-card" id="loginCard">
			
			<!--- Global In-Card Alert Box --->
			<div id="loginErrorAlert" class="login-alert login-alert-danger" style="display:none;" role="alert">
				<span style="flex-shrink:0;">#svgIcon(name="alert-triangle", size=18)#</span>
				<div id="loginErrorMessage" style="flex:1;"></div>
				<button type="button" class="login-alert-dismiss" onclick="clearAlerts()" aria-label="Dismiss error">
					#svgIcon(name="x", size=14)#
				</button>
			</div>

			<div id="loginSuccessAlert" class="login-alert login-alert-success" style="display:none;" role="status">
				<span style="flex-shrink:0;">#svgIcon(name="check-circle", size=18)#</span>
				<div id="loginSuccessMessage" style="flex:1;"></div>
				<button type="button" class="login-alert-dismiss" onclick="clearAlerts()" aria-label="Dismiss alert">
					#svgIcon(name="x", size=14)#
				</button>
			</div>

			<!--- STEP 1: ENTER EMAIL ADDRESS --->
			<div id="step1-container">
				<div class="step-header">
					<h2 class="step-title">Sign In to Your Account</h2>
					<p class="step-desc">Enter your registered Chelan County email address to access your workspace.</p>
				</div>

				<form id="checkEmailForm" onsubmit="handleEmailSubmit(event)" novalidate>
					<div class="form-group-custom">
						<label for="emailInput" class="form-label-custom">County Email Address</label>
						<div class="input-with-icon">
							<span class="input-icon-left">#svgIcon(name="mail", size=18)#</span>
							<input type="email" id="emailInput" name="email" class="form-control-custom" 
							       placeholder="username@chelancounty.gov" 
							       value="#EncodeForHTMLAttribute(Len(variables.prefilledEmail) ? variables.prefilledEmail : (variables.rememberedEmail ?: ''))#" 
							       data-url-prefilled="#(Len(variables.prefilledEmail) ? '1' : '0')#"
							       required autofocus autocomplete="email">
						</div>
					</div>

					<div style="margin-bottom: 1.15rem; padding: 0.7rem 0.9rem; background: ##f8fafc; border: 1px solid ##e2e8f0; border-radius: 10px; display: flex; align-items: center; justify-content: space-between; gap: 0.75rem;">
						<label for="rememberMeCheckbox" style="display: flex; align-items: center; gap: 0.6rem; cursor: pointer; margin: 0; font-size: 0.86rem; font-weight: 600; color: ##1e293b; user-select: none;">
							<input type="checkbox" id="rememberMeCheckbox" name="remember_me" value="1" checked style="width: 17px; height: 17px; accent-color: var(--login-primary); cursor: pointer; flex-shrink: 0;">
							<span>Keep me signed in for 30 days <span style="font-weight: 400; color: ##64748b; font-size: 0.78rem;">(Remember me)</span></span>
						</label>
					</div>

					<button type="submit" id="btnCheckEmail" class="btn-login-primary">
						<span id="btnCheckEmailText">Continue</span>
						<span id="btnCheckEmailIcon">#svgIcon(name="chevron-right", size=16)#</span>
						<span id="btnCheckEmailSpinner" class="spinner-inline" style="display:none;"></span>
					</button>
				</form>
			</div>

			<!--- STEP 2: VERIFICATION & AUTHENTICATOR CHOICE --->
			<div id="step2-container" style="display:none;">
				
				<!--- Retrieved User Profile Banner --->
				<div class="user-profile-badge-card">
					<div class="profile-avatar-circle" id="userAvatar">SJ</div>
					<div class="profile-info">
						<div class="profile-name-row">
							<span class="profile-name" id="userName">Sarah Jenkins</span>
							<span class="badge badge-danger" id="userRoleBadge">Administrator</span>
						</div>
						<div class="profile-email" id="userEmail">sarah.jenkins@chelancounty.gov</div>
						<div class="profile-dept" id="userDepartment">County Administration &bull; Web Administrator</div>
					</div>
					<button type="button" class="btn-switch-account" onclick="resetToStep1()">
						Switch
					</button>
				</div>

				<div class="step-header">
					<h3 class="step-title" style="font-size:1.15rem;">Choose Authentication Method</h3>
					<p class="step-desc">Select how you would like to complete your two-factor verification:</p>
				</div>

				<!--- Three Authentication Choices Cards --->
				<div class="auth-options-grid">
					
					<!--- Option 1: Email OTP --->
					<button type="button" class="auth-option-card" id="optEmailOtp" onclick="chooseAuthMethod('email-otp')">
						<div class="auth-option-icon">
							#svgIcon(name="mail", size=20)#
						</div>
						<div class="auth-option-body">
							<div class="auth-option-title">
								<span>Email One-Time Passcode (OTP)</span>
								<span class="badge badge-neutral" style="font-size:0.7rem; font-weight:600;">Email</span>
							</div>
							<p class="auth-option-desc">Receive a temporary 6-digit passcode in your official inbox.</p>
						</div>
					</button>

					<!--- Option 2: Use Connected Authenticator --->
					<button type="button" class="auth-option-card" id="optAuthenticator" onclick="chooseAuthMethod('authenticator')">
						<div class="auth-option-icon">
							#svgIcon(name="smartphone", size=20)#
						</div>
						<div class="auth-option-body">
							<div class="auth-option-title">
								<span>Use Connected Authenticator</span>
								<span class="badge badge-success" id="authConnectedBadge" style="font-size:0.7rem; font-weight:600;">App Code</span>
							</div>
							<p class="auth-option-desc">Enter the 6-digit TOTP code from Microsoft Authenticator or Google Authenticator.</p>
						</div>
					</button>

					<!--- Option 3: Connect Your Authenticator --->
					<button type="button" class="auth-option-card" id="optConnect" onclick="chooseAuthMethod('connect')">
						<div class="auth-option-icon">
							#svgIcon(name="qr-code", size=20)#
						</div>
						<div class="auth-option-body">
							<div class="auth-option-title">
								<span>Connect Your Authenticator</span>
								<span class="badge badge-primary" style="font-size:0.7rem; font-weight:600;">Pair App</span>
							</div>
							<p class="auth-option-desc">Scan a QR code to link Microsoft Authenticator or Google Authenticator.</p>
						</div>
					</button>

				</div>

				<!--- METHOD PANEL 1: EMAIL OTP --->
				<div id="panel-email-otp" class="method-panel">
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.75rem;">
						<strong style="color:##0f172a; font-size:0.95rem;">Verify with Email Passcode</strong>
						<button type="button" class="btn-switch-account" onclick="closeAllPanels()">Back</button>
					</div>
					<p style="font-size:0.83rem; color:##64748b; margin:0 0 0.85rem 0;" id="otpRecipientText">
						Click the button below to generate and send a 6-digit passcode to your email.
					</p>

					<div id="otpSendState">
						<button type="button" id="btnTriggerSendOtp" class="btn-login-primary" onclick="sendOtpCode()">
							<span>Send One-Time Passcode</span>
							#svgIcon(name="mail", size=16)#
						</button>
					</div>

					<div id="otpInputState" style="display:none;">

						<form id="verifyOtpForm" onsubmit="handleVerifyOtp(event)">
							<div class="form-group-custom">
								<label for="otpInput" class="form-label-custom">Enter 6-Digit Passcode</label>
								<div class="input-with-icon">
									<span class="input-icon-left">#svgIcon(name="lock", size=18)#</span>
									<input type="text" id="otpInput" class="form-control-custom" 
									       placeholder="000000" maxlength="6" pattern="[0-9]{6}" 
									       style="font-family:monospace; font-size:1.2rem; letter-spacing:0.25em; text-align:center;" 
									       autocomplete="one-time-code">
								</div>
							</div>

							<button type="submit" id="btnVerifyOtp" class="btn-login-primary">
								<span>Verify &amp; Sign In</span>
								#svgIcon(name="check", size=16)#
							</button>
						</form>

						<div style="margin-top:0.85rem; text-align:center;">
							<button type="button" onclick="sendOtpCode()" style="background:none; border:none; font-size:0.8rem; color:var(--login-primary); font-weight:600; cursor:pointer; text-decoration:underline;">
								Resend Passcode
							</button>
						</div>
					</div>
				</div>

				<!--- METHOD PANEL 2: USE CONNECTED AUTHENTICATOR --->
				<div id="panel-authenticator" class="method-panel">
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.75rem;">
						<strong style="color:##0f172a; font-size:0.95rem;">Authenticator App Code</strong>
						<button type="button" class="btn-switch-account" onclick="closeAllPanels()">Back</button>
					</div>

					<p style="font-size:0.83rem; color:##64748b; margin:0 0 0.85rem 0;">
						Open Microsoft Authenticator or Google Authenticator and enter the current 6-digit code.
					</p>

					<form id="verifyAuthForm" onsubmit="handleVerifyAuthenticator(event)">
						<div class="form-group-custom">
							<label for="authCodeInput" class="form-label-custom">6-Digit Authenticator Code</label>
							<div class="input-with-icon">
								<span class="input-icon-left">#svgIcon(name="smartphone", size=18)#</span>
								<input type="text" id="authCodeInput" class="form-control-custom" 
								       placeholder="000000" maxlength="6" pattern="[0-9]{6}" 
								       style="font-family:monospace; font-size:1.2rem; letter-spacing:0.25em; text-align:center;" 
								       autocomplete="one-time-code" required>
							</div>
						</div>

						<button type="submit" id="btnVerifyAuth" class="btn-login-primary">
							<span>Verify &amp; Sign In</span>
							#svgIcon(name="check", size=16)#
						</button>
					</form>
				</div>

				<!--- METHOD PANEL 3: CONNECT / SET UP AUTHENTICATOR --->
				<div id="panel-connect" class="method-panel">
					<div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:0.75rem;">
						<strong style="color:##0f172a; font-size:0.95rem;">Connect Authenticator App</strong>
						<button type="button" class="btn-switch-account" onclick="closeAllPanels()">Back</button>
					</div>

					<p style="font-size:0.83rem; color:##64748b; margin:0 0 1rem 0;">
						Pair Google Authenticator or Microsoft Authenticator by scanning the QR code below:
					</p>

					<div class="qr-setup-box">
						<div id="qrContainer" style="display:flex; justify-content:center;">
							<img id="qrImage" src="" alt="Authenticator Setup QR Code" class="qr-code-img">
						</div>

						<div style="font-size:0.78rem; color:##64748b; margin-bottom:0.35rem;">
							Can't scan? Enter this manual configuration key in your app:
						</div>
						
						<div class="secret-key-display">
							<span id="totpSecretFormatted">ABCD EFGH IJKL MNOP</span>
							<button type="button" class="btn-copy-secret" onclick="copySecretKey()">
								Copy
							</button>
						</div>
					</div>

					<form id="saveAuthForm" onsubmit="handleSaveAuthenticator(event)">
						<input type="hidden" id="rawSecretInput" name="secret" value="">
						<div class="form-group-custom">
							<label for="connectCodeInput" class="form-label-custom">Confirmation Code</label>
							<div class="input-with-icon">
								<span class="input-icon-left">#svgIcon(name="key", size=18)#</span>
								<input type="text" id="connectCodeInput" class="form-control-custom" 
								       placeholder="000000" maxlength="6" pattern="[0-9]{6}" 
								       style="font-family:monospace; font-size:1.2rem; letter-spacing:0.25em; text-align:center;" 
								       required>
							</div>
						</div>

						<button type="submit" id="btnSaveAuth" class="btn-login-primary">
							<span>Confirm &amp; Complete Sign In</span>
							#svgIcon(name="check", size=16)#
						</button>
					</form>
				</div>

			</div>

		</div>

		<!--- Footer security note --->
		<div class="login-footer-info">
			Chelan County Information Technology &bull; 400 Douglas Street, Wenatchee, WA 98801<br>
			Need help? Contact IT Support at <a href="mailto:support@chelancounty.gov">support@chelancounty.gov</a> or (509) 667-6215.
		</div>
	</div>

	<!--- Client-Side Authentication Controller Script --->
	<script>
		var currentUser = null;
		var activeAuthMethod = null;
		var currentSecret = "";

		// Deep normalizer that mirrors all object keys in lowercase, uppercase, and original casing
		function normalizeKeys(obj) {
			if (!obj || typeof obj !== 'object') return obj;
			if (Array.isArray(obj)) return obj.map(normalizeKeys);
			var newObj = {};
			for (var key in obj) {
				if (Object.prototype.hasOwnProperty.call(obj, key)) {
					var val = normalizeKeys(obj[key]);
					newObj[key.toLowerCase()] = val;
					newObj[key.toUpperCase()] = val;
					newObj[key] = val;
				}
			}
			return newObj;
		}

		var flashAutoHider = null;
		var errorAutoHider = null;
		var successAutoHider = null;

		/**
		 * Attaches an auto-dismiss timer to an alert element with pause-on-hover support.
		 * Automatically smoothly fades out the element after delayMs.
		 */
		function attachAutoHideWithPause(el, delayMs, onHidden) {
			if (!el) return null;
			var timeoutId = null;
			var remaining = delayMs || 5000;
			var startTime = Date.now();
			var isPaused = false;

			function start() {
				startTime = Date.now();
				timeoutId = setTimeout(function() {
					el.style.transition = 'opacity 0.45s ease, transform 0.45s ease';
					el.style.opacity = '0';
					el.style.transform = 'translateY(-6px)';
					setTimeout(function() {
						el.style.display = 'none';
						el.style.opacity = '';
						el.style.transform = '';
						el.style.transition = '';
						if (typeof onHidden === 'function') onHidden();
					}, 450);
				}, remaining);
			}

			function pause() {
				if (timeoutId) {
					clearTimeout(timeoutId);
					timeoutId = null;
					remaining = Math.max(1000, remaining - (Date.now() - startTime));
					isPaused = true;
				}
			}

			function resume() {
				if (isPaused && el.style.display !== 'none') {
					isPaused = false;
					start();
				}
			}

			el.addEventListener('mouseenter', pause);
			el.addEventListener('mouseleave', resume);

			start();

			return {
				cancel: function() {
					if (timeoutId) clearTimeout(timeoutId);
					timeoutId = null;
					el.removeEventListener('mouseenter', pause);
					el.removeEventListener('mouseleave', resume);
				}
			};
		}

		document.addEventListener('DOMContentLoaded', function() {
			// Auto-hide session / flash messages if present (after 5 seconds, pauses on hover)
			var flashContainer = document.getElementById('flashAlertContainer');
			if (flashContainer && flashContainer.innerText.trim().length > 0) {
				flashAutoHider = attachAutoHideWithPause(flashContainer, 5000, function() {
					flashContainer.innerHTML = '';
					flashAutoHider = null;
				});

				flashContainer.addEventListener('click', function(e) {
					var closeBtn = e.target.closest('.alert-close, [data-dismiss="alert"]');
					if (closeBtn) {
						if (flashAutoHider) { flashAutoHider.cancel(); flashAutoHider = null; }
						flashContainer.innerHTML = '';
					}
				});
			}

			// Dismiss error alert automatically when user resumes typing
			['emailInput', 'otpInput', 'authCodeInput', 'connectCodeInput'].forEach(function(id) {
				var inputEl = document.getElementById(id);
				if (inputEl) {
					inputEl.addEventListener('input', function() {
						var errAlert = document.getElementById('loginErrorAlert');
						if (errAlert && errAlert.style.display !== 'none') {
							clearAlerts();
						}
					});
				}
			});

			var emailEl = document.getElementById('emailInput');
			var prefilled = emailEl ? emailEl.value.trim() : '';
			var isUrlPrefilled = emailEl && emailEl.getAttribute('data-url-prefilled') === '1';
			if (isUrlPrefilled && prefilled.length > 0 && prefilled.indexOf('@') > 0) {
				lookupEmail(prefilled);
			}
		});

		function selectDemoUser(email) {
			document.getElementById('emailInput').value = email;
			lookupEmail(email);
		}

		function fillCode(fieldId, code) {
			var el = document.getElementById(fieldId);
			if (el) {
				el.value = code;
				el.focus();
			}
		}

		function showError(msg) {
			var errAlert = document.getElementById('loginErrorAlert');
			var errMsg = document.getElementById('loginErrorMessage');
			var succAlert = document.getElementById('loginSuccessAlert');
			if (succAlert) {
				if (successAutoHider) { successAutoHider.cancel(); successAutoHider = null; }
				succAlert.style.display = 'none';
			}
			if (errorAutoHider) {
				errorAutoHider.cancel();
				errorAutoHider = null;
			}
			if (errAlert && errMsg) {
				errMsg.innerHTML = msg;
				errAlert.style.transition = '';
				errAlert.style.opacity = '1';
				errAlert.style.transform = 'translateY(0)';
				errAlert.style.display = 'flex';
				errAlert.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

				// Auto-hide error message after 5 seconds (pauses on hover)
				errorAutoHider = attachAutoHideWithPause(errAlert, 5000, function() {
					errorAutoHider = null;
				});
			}
		}

		function showSuccess(msg) {
			var succAlert = document.getElementById('loginSuccessAlert');
			var succMsg = document.getElementById('loginSuccessMessage');
			var errAlert = document.getElementById('loginErrorAlert');
			if (errAlert) {
				if (errorAutoHider) { errorAutoHider.cancel(); errorAutoHider = null; }
				errAlert.style.display = 'none';
			}
			if (successAutoHider) {
				successAutoHider.cancel();
				successAutoHider = null;
			}
			if (succAlert && succMsg) {
				succMsg.innerHTML = msg;
				succAlert.style.transition = '';
				succAlert.style.opacity = '1';
				succAlert.style.transform = 'translateY(0)';
				succAlert.style.display = 'flex';

				// Auto-hide success message after 5 seconds (pauses on hover)
				successAutoHider = attachAutoHideWithPause(succAlert, 5000, function() {
					successAutoHider = null;
				});
			}
		}

		function clearAlerts() {
			if (errorAutoHider) { errorAutoHider.cancel(); errorAutoHider = null; }
			if (successAutoHider) { successAutoHider.cancel(); successAutoHider = null; }
			var errAlert = document.getElementById('loginErrorAlert');
			var succAlert = document.getElementById('loginSuccessAlert');
			if (errAlert) errAlert.style.display = 'none';
			if (succAlert) succAlert.style.display = 'none';
		}

		function handleEmailSubmit(e) {
			if (e) e.preventDefault();
			var email = document.getElementById('emailInput').value.trim();
			if (!email) {
				showError('Please enter an email address.');
				return;
			}
			lookupEmail(email);
		}

		function lookupEmail(email) {
			clearAlerts();
			setLoading(true);

			var csrfToken = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';

			var formData = new FormData();
			formData.append('email', email);
			if (csrfToken) formData.append('authenticityToken', csrfToken);

			fetch('/login/check-email', {
				method: 'POST',
				headers: {
					'Accept': 'application/json',
					'X-Requested-With': 'XMLHttpRequest'
				},
				body: formData
			})
			.then(function(res) {
				return res.json();
			})
			.then(function(raw) {
				var data = normalizeKeys(raw);
				setLoading(false);
				if ((data.success || raw.SUCCESS) && (data.user || raw.USER)) {
					currentUser = data.user || raw.USER;
					renderStep2(currentUser);
				} else {
					showError(data.message || raw.MESSAGE || 'Email not found in database.');
				}
			})
			.catch(function(err) {
				setLoading(false);
				showError('Network error checking email. Please try again.');
			});
		}

		function setLoading(loading) {
			var btn = document.getElementById('btnCheckEmail');
			var text = document.getElementById('btnCheckEmailText');
			var icon = document.getElementById('btnCheckEmailIcon');
			var spinner = document.getElementById('btnCheckEmailSpinner');

			if (loading) {
				btn.disabled = true;
				if (text) text.innerText = 'Checking Database...';
				if (icon) icon.style.display = 'none';
				if (spinner) spinner.style.display = 'inline-block';
			} else {
				btn.disabled = false;
				if (text) text.innerText = 'Continue';
				if (icon) icon.style.display = 'inline-block';
				if (spinner) spinner.style.display = 'none';
			}
		}

		function renderStep2(user) {
			clearAlerts();
			document.getElementById('step1-container').style.display = 'none';
			document.getElementById('step2-container').style.display = 'block';

			var firstName = user.first_name || user.FIRST_NAME || '';
			var lastName = user.last_name || user.LAST_NAME || '';
			var fullName = user.full_name || user.FULL_NAME || (firstName + ' ' + lastName).trim() || 'Chelan County User';
			var email = user.email || user.EMAIL || '';
			var initials = user.initials || user.INITIALS || (firstName && lastName ? (firstName[0] + lastName[0]).toUpperCase() : 'U');
			var roleName = user.role_name || user.ROLE_NAME || 'User';
			var roleBadge = user.role_badge || user.ROLE_BADGE || 'badge-primary';
			var jobTitle = user.job_title || user.JOB_TITLE || 'County Staff';
			var deptName = user.department_name || user.DEPARTMENT_NAME || 'Chelan County';
			var isConnected = (user.totp_connected === true || user.totp_connected === 1 || user.totp_connected === '1' || user.TOTP_CONNECTED === true || user.TOTP_CONNECTED === 1 || user.TOTP_CONNECTED === '1');

			document.getElementById('userName').innerText = fullName;
			document.getElementById('userEmail').innerText = email;
			document.getElementById('userAvatar').innerText = initials;

			var badge = document.getElementById('userRoleBadge');
			badge.innerText = roleName;
			badge.className = 'badge ' + roleBadge;

			var deptText = jobTitle + ' \u2022 ' + deptName;
			document.getElementById('userDepartment').innerText = deptText;

			var authBadge = document.getElementById('authConnectedBadge');
			if (isConnected) {
				authBadge.innerText = 'Connected';
				authBadge.className = 'badge badge-success';
			} else {
				authBadge.innerText = 'Available';
				authBadge.className = 'badge badge-neutral';
			}

			closeAllPanels();
		}

		function resetToStep1() {
			clearAlerts();
			currentUser = null;
			activeAuthMethod = null;
			closeAllPanels();
			document.getElementById('step2-container').style.display = 'none';
			document.getElementById('step1-container').style.display = 'block';
			document.getElementById('emailInput').focus();
		}

		function chooseAuthMethod(method) {
			clearAlerts();
			activeAuthMethod = method;

			document.getElementById('optEmailOtp').classList.remove('is-selected');
			document.getElementById('optAuthenticator').classList.remove('is-selected');
			document.getElementById('optConnect').classList.remove('is-selected');

			closeAllPanels();

			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';

			if (method === 'email-otp') {
				document.getElementById('optEmailOtp').classList.add('is-selected');
				document.getElementById('panel-email-otp').classList.add('is-active');
				document.getElementById('otpRecipientText').innerText = 'Send a one-time passcode to ' + userEmail + '.';
			} else if (method === 'authenticator') {
				document.getElementById('optAuthenticator').classList.add('is-selected');
				document.getElementById('panel-authenticator').classList.add('is-active');
				var codeInput = document.getElementById('authCodeInput');
				if (codeInput) {
					codeInput.value = '';
					codeInput.focus();
				}
			} else if (method === 'connect') {
				document.getElementById('optConnect').classList.add('is-selected');
				document.getElementById('panel-connect').classList.add('is-active');
				loadConnectDetails();
			}
		}

		function closeAllPanels() {
			document.getElementById('panel-email-otp').classList.remove('is-active');
			document.getElementById('panel-authenticator').classList.remove('is-active');
			document.getElementById('panel-connect').classList.remove('is-active');
			document.getElementById('optEmailOtp').classList.remove('is-selected');
			document.getElementById('optAuthenticator').classList.remove('is-selected');
			document.getElementById('optConnect').classList.remove('is-selected');
		}

		function sendOtpCode() {
			clearAlerts();
			var csrfToken = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';

			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';
			var formData = new FormData();
			formData.append('email', userEmail);
			if (csrfToken) formData.append('authenticityToken', csrfToken);

			var btn = document.getElementById('btnTriggerSendOtp');
			btn.disabled = true;
			btn.innerHTML = '<span class="spinner-inline"></span> Sending Code...';

			fetch('/login/send-otp', {
				method: 'POST',
				headers: {
					'Accept': 'application/json',
					'X-Requested-With': 'XMLHttpRequest'
				},
				body: formData
			})
			.then(function(res) { return res.json(); })
			.then(function(raw) {
				var data = normalizeKeys(raw);
				btn.disabled = false;
				btn.innerHTML = 'Send One-Time Passcode';
				if (data.success || raw.SUCCESS) {
					document.getElementById('otpSendState').style.display = 'none';
					document.getElementById('otpInputState').style.display = 'block';
					var devCode = data.devotp || raw.DEVOTP || raw.devOtp || '';
					if (devCode) {
						document.getElementById('devOtpDisplay').innerText = devCode;
					}
					showSuccess(data.message || raw.MESSAGE || 'Passcode sent!');
					var inp = document.getElementById('otpInput');
					inp.value = '';
					inp.focus();
				} else {
					showError(data.message || raw.MESSAGE || 'Failed to send OTP.');
				}
			})
			.catch(function(err) {
				btn.disabled = false;
				btn.innerHTML = 'Send One-Time Passcode';
				showError('Failed to send OTP. Please try again.');
			});
		}

		function handleVerifyOtp(e) {
			if (e) e.preventDefault();
			clearAlerts();
			var code = document.getElementById('otpInput').value.trim();
			if (!code) {
				showError('Please enter the 6-digit passcode.');
				return;
			}

			var btn = document.getElementById('btnVerifyOtp');
			btn.disabled = true;
			btn.innerHTML = '<span class="spinner-inline"></span> Verifying...';

			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';
			var csrfToken = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';
			var formData = new FormData();
			formData.append('email', userEmail);
			formData.append('code', code);
			var remEl = document.getElementById('rememberMeCheckbox');
			formData.append('remember_me', (!remEl || remEl.checked) ? '1' : '0');
			if (csrfToken) formData.append('authenticityToken', csrfToken);

			fetch('/login/verify-otp', {
				method: 'POST',
				headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
				body: formData
			})
			.then(function(res) { return res.json(); })
			.then(function(raw) {
				var data = normalizeKeys(raw);
				btn.disabled = false;
				btn.innerHTML = '<span>Verify &amp; Sign In</span>';
				if (data.success || raw.SUCCESS) {
					window.location.href = data.redirect || raw.REDIRECT || '/';
				} else {
					showError(data.message || raw.MESSAGE || 'Invalid passcode.');
				}
			})
			.catch(function(err) {
				btn.disabled = false;
				btn.innerHTML = '<span>Verify &amp; Sign In</span>';
				showError('Verification error. Please retry.');
			});
		}

		function handleVerifyAuthenticator(e) {
			if (e) e.preventDefault();
			clearAlerts();
			var code = document.getElementById('authCodeInput').value.trim();
			if (!code) {
				showError('Please enter the 6-digit authenticator code.');
				return;
			}

			var btn = document.getElementById('btnVerifyAuth');
			btn.disabled = true;
			btn.innerHTML = '<span class="spinner-inline"></span> Verifying...';

			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';
			var csrfToken = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';
			var formData = new FormData();
			formData.append('email', userEmail);
			formData.append('code', code);
			var remEl = document.getElementById('rememberMeCheckbox');
			formData.append('remember_me', (!remEl || remEl.checked) ? '1' : '0');
			if (csrfToken) formData.append('authenticityToken', csrfToken);

			fetch('/login/verify-authenticator', {
				method: 'POST',
				headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
				body: formData
			})
			.then(function(res) { return res.json(); })
			.then(function(raw) {
				var data = normalizeKeys(raw);
				btn.disabled = false;
				btn.innerHTML = '<span>Verify &amp; Sign In</span>';
				if (data.success || raw.SUCCESS) {
					window.location.href = data.redirect || raw.REDIRECT || '/';
				} else {
					showError(data.message || raw.MESSAGE || 'Invalid authenticator code.');
				}
			})
			.catch(function(err) {
				btn.disabled = false;
				btn.innerHTML = '<span>Verify &amp; Sign In</span>';
				showError('Verification error. Please retry.');
			});
		}

		function loadConnectDetails() {
			clearAlerts();
			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';
			fetch('/login/connect-authenticator?email=' + encodeURIComponent(userEmail), {
				headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
			})
			.then(function(res) { return res.json(); })
			.then(function(raw) {
				var data = normalizeKeys(raw);
				if (data.success || raw.SUCCESS) {
					currentSecret = data.secret || raw.SECRET || '';
					document.getElementById('rawSecretInput').value = currentSecret;
					document.getElementById('totpSecretFormatted').innerText = data.formattedsecret || raw.FORMATTEDSECRET || currentSecret;

					var qrImg = document.getElementById('qrImage');
					var otpUri = data.otpauth || raw.OTPAUTH || '';
					var encodedOtpauth = encodeURIComponent(otpUri);
					qrImg.src = 'https://api.qrserver.com/v1/create-qr-code/?size=170x170&margin=4&data=' + encodedOtpauth;

					var codeInput = document.getElementById('connectCodeInput');
					codeInput.value = '';
					codeInput.focus();
				} else {
					showError(data.message || raw.MESSAGE || 'Could not initiate authenticator setup.');
				}
			})
			.catch(function(err) {
				showError('Could not load authenticator setup details.');
			});
		}

		async function copySecretKey() {
			if (!currentSecret) return;
			var ok = typeof window.copyToClipboard === 'function'
				? await window.copyToClipboard(currentSecret)
				: false;
			if (!ok) {
				try {
					var ta = document.createElement('textarea');
					ta.value = currentSecret;
					ta.style.position = 'fixed';
					ta.style.opacity = '0';
					document.body.appendChild(ta);
					ta.focus();
					ta.select();
					ok = document.execCommand('copy');
					document.body.removeChild(ta);
				} catch(e) {}
			}
			if (ok) {
				showSuccess('Secret key copied to clipboard!');
			} else {
				showSuccess('Secret key: ' + currentSecret);
			}
		}

		function handleSaveAuthenticator(e) {
			if (e) e.preventDefault();
			clearAlerts();
			var code = document.getElementById('connectCodeInput').value.trim();
			if (!code) {
				showError('Please enter confirmation code.');
				return;
			}

			var btn = document.getElementById('btnSaveAuth');
			btn.disabled = true;
			btn.innerHTML = '<span class="spinner-inline"></span> Connecting...';

			var userEmail = currentUser ? (currentUser.email || currentUser.EMAIL || '') : '';
			var csrfToken = document.querySelector('meta[name="csrf-token"]') ? document.querySelector('meta[name="csrf-token"]').getAttribute('content') : '';
			var formData = new FormData();
			formData.append('email', userEmail);
			formData.append('code', code);
			var remEl = document.getElementById('rememberMeCheckbox');
			formData.append('remember_me', (!remEl || remEl.checked) ? '1' : '0');
			formData.append('secret', currentSecret);
			if (csrfToken) formData.append('authenticityToken', csrfToken);

			fetch('/login/save-authenticator', {
				method: 'POST',
				headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' },
				body: formData
			})
			.then(function(res) { return res.json(); })
			.then(function(raw) {
				var data = normalizeKeys(raw);
				btn.disabled = false;
				btn.innerHTML = '<span>Confirm &amp; Complete Sign In</span>';
				if (data.success || raw.SUCCESS) {
					window.location.href = data.redirect || raw.REDIRECT || '/';
				} else {
					showError(data.message || raw.MESSAGE || 'Invalid confirmation code.');
				}
			})
			.catch(function(err) {
				btn.disabled = false;
				btn.innerHTML = '<span>Confirm &amp; Complete Sign In</span>';
				showError('Pairing error. Please retry.');
			});
		}
	</script>
</body>
</html>
</cfoutput>
