module Specjour
  class Dispatcher
    require 'dnssd'
    attr_reader :project_path, :managers, :manager_threads, :hosts, :worker_size

    def initialize(project_path)
      @project_path = project_path
      @managers = []
      @worker_size = 0
      reset_manager_threads
    end

    def all_specs
      @all_specs ||= Dir.chdir(project_path) do
        Dir["spec/**/**/*_spec.rb"].sort
      end
    end

    def project_name
      @project_name ||= File.basename(project_path)
    end

    def start
      rsync_daemon.start
      gather_managers
      sync_managers
      dispatch_work
      wait_for_socket
      report.summarize
    end

    def wait_for_socket
      client_size = 0
      threads = []
      loop do
        threads << Thread.new(socket_server.accept) do |client|
          client_size += 1
          client.each(Specjour::TERMINATOR) do |data|
            process Marshal.load(data.sub(/#{Specjour::TERMINATOR}/, ''))
          end
          client.close
        end
        if client_size == worker_size
          threads.each {|t| t.join}
          break
        end
      end
    end

    def process(message)
      if message.is_a?(String)
        $stdout.print message
        $stdout.flush
      elsif message.is_a?(Array)
        send(message.first, message[1])
      end
    end

    def socket_server
      @socket_server ||= TCPServer.open(0)
    end

    def add_to_report(stats)
      report.add(stats)
    end

    def report
      @report ||= FinalReport.new
    end

    def worker_summary=(summary)
      report.add(summary)
    end

    protected

    def dispatch_work
      managers.each do |manager|
        specs_to_run = []
        (1..manager.worker_size).each do |index|
          specs_to_run << Array(specs_for_worker(index - 1))
        end
        manager.specs_to_run = [send("suite0"), send("suite1")]
        # manager.specs_to_run = specs_to_run
        Thread.new(manager) {|m| m.dispatch}
      end
    end

    def drb_start
      DRb.start_service nil, self
      at_exit { puts 'shutting down DRb client'; DRb.stop_service }
    end

    def fetch_manager(uri)
      manager = DRbObject.new_with_uri(uri.to_s)
      unless managers.include?(manager)
        set_up_manager(manager, uri)
        managers << manager
        @worker_size += manager.worker_size
      end
    end

    def set_up_manager(manager, uri)
      manager.project_name = project_name
      manager.host = hostname
      manager.dispatcher_uri = "specjour://#{hostname}:#{socket_server.addr[1]}"
    end

    def gather_managers
      browser = DNSSD::Service.new
      browser.browse '_druby._tcp' do |reply|
        if reply.flags.add?
          resolve_reply(reply)
        end
        browser.stop unless reply.flags.more_coming?
      end
      puts "Managers found: #{managers.size}"
    end

    def hostname
      @hostname ||= Socket.gethostname
    end

    def reset_manager_threads
      @manager_threads = []
    end

    def resolve_reply(reply)
      DNSSD.resolve!(reply) do |resolved|
        uri = URI::Generic.build :scheme => reply.service_name, :host => resolved.target, :port => resolved.port
        fetch_manager(uri)
        resolved.service.stop if resolved.service.started?
      end
    end

    def rsync_daemon
      @rsync_daemon ||= RsyncDaemon.new(project_path, project_name)
    end

    def specs_for_worker(index)
      offset = (index * specs_per_worker)
      boundry = specs_per_worker * (index + 1)
      range = (offset...boundry)
      if (index + 1) == worker_size
        range = (offset..-1)
      end
      all_specs[range]
    end

    def specs_per_worker
      per = all_specs.size / worker_size
      per.zero? ? 1 : per
    end

    def sync_managers
      managers.each do |manager|
        manager_threads << Thread.new(manager) { |manager| manager.sync }
      end
      wait_on_managers
    end

    def wait_on_managers
      manager_threads.each {|t| t.join; t.exit}
      reset_manager_threads
    end

    def suite0
      %w(
spec/config/initializers/becomes_spec.rb spec/controllers/colleagues_controller_spec.rb spec/controllers/dashboards_controller_spec.rb spec/controllers/email/openings_controller_spec.rb spec/controllers/homes_controller_spec.rb spec/controllers/individual_payment_informations_controller_spec.rb spec/controllers/users_controller_spec.rb spec/helpers/application_helper_spec.rb spec/helpers/offers_helper_spec.rb spec/helpers/openings_helper_spec.rb spec/helpers/users_helper_spec.rb spec/integration/admin_marks_invoice_paid_spec.rb spec/integration/admin_marks_invoice_sent_spec.rb spec/integration/admin_sends_invoice_payments_spec.rb spec/integration/admin_signs_in_spec.rb spec/integration/admin_verifies_dossier_spec.rb spec/integration/admin_views_finished_invoice_spec.rb spec/integration/admin_views_make_payments_list_spec.rb_spec.rb spec/integration/admin_views_outstanding_invoice_detail_spec.rb spec/integration/admin_views_outstanding_invoices_spec.rb spec/integration/colleague_import_spec.rb spec/integration/fellowships_spec.rb spec/integration/job_actions_spec.rb spec/integration/last_action_for_opening_spec.rb spec/integration/manager_accepts_counteroffer_spec.rb spec/integration/manager_approves_timesheet_spec.rb spec/integration/manager_cancels_acceptance_spec.rb spec/integration/manager_counters_counteroffer_spec.rb spec/integration/manager_creates_job_offer_spec.rb spec/integration/manager_creates_job_spec.rb spec/integration/manager_edits_job_spec.rb spec/integration/manager_makes_instant_offer_spec.rb spec/integration/manager_rejects_timesheet_spec.rb spec/integration/manager_reviews_timesheet_spec.rb spec/integration/manager_sends_job_spec.rb spec/integration/manager_views_a_job_spec.rb spec/integration/manager_views_counteroffer_spec.rb spec/integration/manager_views_created_jobs_spec.rb spec/integration/manager_views_sow_spec.rb spec/integration/manager_views_timesheet_history_spec.rb spec/integration/opening_distribution_spec.rb spec/integration/search_colleagues_spec.rb spec/integration/stale_email_links_spec.rb spec/integration/user_accepts_colleague_request_spec.rb spec/integration/user_accepts_counteroffer_spec.rb spec/integration/user_accepts_offer_spec.rb
      )
    end

    def suite1
      %w(
spec/integration/user_applies_for_job_spec.rb spec/integration/user_creates_timesheet_spec.rb spec/integration/user_declines_offer_spec.rb spec/integration/user_enters_corporate_payment_information_spec.rb spec/integration/user_enters_individual_payment_information_spec.rb spec/integration/user_ignores_colleague_request_spec.rb spec/integration/user_redirects_after_login_spec.rb spec/integration/user_refers_job_spec.rb spec/integration/user_removes_colleague_spec.rb spec/integration/user_sends_counteroffer_spec.rb spec/integration/user_signup_spec.rb spec/integration/user_updates_basic_profile_info_spec.rb spec/integration/user_views_accepted_job_spec.rb spec/integration/user_views_accepted_jobs_spec.rb spec/integration/user_views_colleagues_list_spec.rb spec/integration/user_views_dashboard_spec.rb spec/integration/user_views_job_referrals_spec.rb spec/integration/user_views_offered_job_spec.rb spec/integration/user_views_profile_spec.rb spec/integration/user_views_referred_job_spec.rb spec/integration/user_views_requested_colleague_spec.rb spec/integration/user_views_timesheets_spec.rb spec/lib/contact_csv_spec.rb spec/lib/expensable_spec.rb spec/lib/numeric_writer_spec.rb spec/lib/pop_list_spec.rb spec/lib/start_end_date_validations_spec.rb spec/models/address_spec.rb spec/models/alternate_email_spec.rb spec/models/colleague_import_spec.rb spec/models/contract_invoice_spec.rb spec/models/contract_job_spec.rb spec/models/contract_offer_spec.rb spec/models/contract_opening_spec.rb spec/models/corporate_payment_information_spec.rb spec/models/delayed_job_observer_spec.rb spec/models/dossier_spec.rb spec/models/expense_category_spec.rb spec/models/expense_receipt_spec.rb spec/models/fellowship_spec.rb spec/models/individual_payment_information_spec.rb spec/models/invited_user_from_distribution_spec.rb spec/models/invited_user_spec.rb spec/models/invoice_spec.rb spec/models/job_application_spec.rb spec/models/job_spec.rb spec/models/notifier_spec.rb spec/models/offer_spec.rb spec/models/opening_spec.rb spec/models/payment_spec.rb spec/models/permanent_invoice_spec.rb spec/models/permanent_job_spec.rb spec/models/permanent_offer_spec.rb spec/models/permanent_opening_spec.rb spec/models/phone_spec.rb spec/models/referral_payment_spec.rb spec/models/referral_spec.rb spec/models/referred_opening_sorter_spec.rb spec/models/sap_skill_spec.rb spec/models/statement_of_work_spec.rb spec/models/timesheet_payment_spec.rb spec/models/timesheet_spec.rb spec/models/user_session_spec.rb spec/models/user_spec.rb spec/views/alternate_emails/new.html_spec.rb spec/views/payments/index.html_spec.rb
      )
    end
  end
end
__END__
queue
  dispatcher => 2 workers
  worker => specs1
  worker => specs2
  dispatcher => results
  dispatcher => results
