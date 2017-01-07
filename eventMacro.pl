package eventMacro;

use lib $Plugins::current_plugin_folder;

use strict;
use Getopt::Long qw( GetOptionsFromArray );
use Time::HiRes qw( &time );
use Plugins;
use Settings;
use Globals;
use Utils;
use Misc;
use Log qw(message error warning debug);
use Translation qw( T TF );
use AI;

use eventMacro::Core;
use eventMacro::Data;
use eventMacro::Lists;
use eventMacro::Automacro;
use eventMacro::FileParser;
use eventMacro::Macro;
use eventMacro::Runner;


Plugins::register('eventMacro', 'allows usage of eventMacros', \&Unload);

my $hooks = Plugins::addHooks(
	['configModify', \&onConfigModify, undef],
	['start3',       \&onstart3, undef],
	['pos_load_config.txt',       \&checkConfig, undef],
);

my $chooks = Commands::register(
	['eventMacro', "eventMacro plugin", \&commandHandler]
);

my $file_handle;
my $file;

sub Unload {
	message "[eventMacro] Plugin unloading\n", "system";
	Settings::removeFile($file_handle) if defined $file_handle;
	undef $file_handle;
	undef $file;
	if (defined $eventMacro) {
		$eventMacro->unload();
		undef $eventMacro;
	}
	Plugins::delHooks($hooks);
	Commands::unregister($chooks);
}

sub checkConfig {
	$timeout{eventMacro_delay}{timeout} = 1 unless defined $timeout{eventMacro_delay};
	$config{eventMacro_orphans} = 'terminate' unless defined $config{eventMacro_orphans};
	$config{eventMacro_CheckOnAI} = 'auto' unless defined $config{eventMacro_CheckOnAI};
	$file = (defined $config{eventMacro_file}) ? $config{eventMacro_file} : "eventMacros.txt";
	return 1;
}

sub onstart3 {
	debug "[eventMacro] Loading start\n", "eventMacro", 2;
	$file_handle = Settings::addControlFile($file,loader => [\&parseAndHook], mustExist => 0);
	Settings::loadByHandle($file_handle);
}

sub onConfigModify {
	my (undef, $args) = @_;
	if ($args->{key} eq 'eventMacro_file') {
		Settings::removeFile($file_handle);
		$file_handle = Settings::addControlFile($args->{val}, loader => [ \&parseAndHook]);
		Settings::loadByHandle($file_handle);
	}
}

sub parseAndHook {
	my $file = shift;
	debug "[eventMacro] Starting to parse file '$file'\n", "eventMacro", 2;
	if (defined $eventMacro) {
		debug "[eventMacro] Plugin global variable '\$eventMacro' is already defined, this must be a file reload. Unloading all current config.\n", "eventMacro", 2;
		$eventMacro->unload();
		undef $eventMacro;
		debug "[eventMacro] Plugin global variable '\$eventMacro' was set to undefined.\n", "eventMacro", 2;
	}
	$eventMacro = new eventMacro::Core($file);
	if (defined $eventMacro) {
		debug "[eventMacro] Loading success\n", "eventMacro", 2;
	} else {
		debug "[eventMacro] Loading error\n", "eventMacro", 2;
	}
}

sub commandHandler {
	### no parameter given
	if (!defined $_[1]) {
		message "usage: eventMacro [MACRO|list|status|stop|pause|resume|reset] [automacro]\n", "list";
		message 
			"eventMacro MACRO: Run macro MACRO\n".
			"eventMacro auto AUTOMACRO: Get info on an automacro and it's conditions\n".
			"eventMacro list: Lists available macros and automacros\n".
			"eventMacro status [macro|automacro]: Shows current status of automacro, macro or both\n".
			"eventMacro check [force_stop|force_start|resume]: Sets the state of automacros checking\n".
			"eventMacro stop: Stops current running macro\n".
			"eventMacro pause: Pauses current running macro\n".
			"eventMacro unpause: Unpauses current running macro\n".
			"eventMacro var_get: Shows the value of one or all variables\n".
			"eventMacro var_set: Set the value of a variable\n".
			"eventMacro enable [automacro]: Enable one or all automacros\n".
			"eventMacro disable [automacro]: Disable one or all automacros\n";
		return
	}
	my ( $arg, @params ) = parseArgs( $_[1] );
	
	if ($arg eq 'auto') {
		my $automacro = $eventMacro->{Automacro_List}->getByName($params[0]);
		if (!$automacro) {
			error "[eventMacro] Automacro '".$params[0]."' not found.\n"
		} else {
			my $message = "[eventMacro] Printing information about automacro '".$automacro->get_name."'.\n";
			my $condition_list = $automacro->{conditionList};
			my $size = $condition_list->size;
			my $is_event = $automacro->has_event_type_condition;
			$message .= "Number of conditions: '".$size."'\n";
			$message .= "Has event type condition: '". ($is_event ? 'yes' : 'no') ."'\n";
			$message .= "Number of true conditions: '".($size - $automacro->{number_of_false_conditions} - $is_event)."'\n";
			$message .= "Number of false conditions: '".$automacro->{number_of_false_conditions}."'\n";
			$message .= "Is triggered: '".$automacro->running_status."'\n";
			
			$message .= "----  Parameters   ----\n";
			my $counter = 1;
			foreach my $parameter (keys %{$automacro->{parameters}}) {
				$message .= $counter." - ".$parameter.": '".$automacro->{parameters}->{$parameter}."'\n";
			} continue {
				$counter++;
			}
			
			$message .= "----  Conditions   ----\n";
			$counter = 1;
			foreach my $condition (@{$condition_list->getItems}) {
				if ($condition->condition_type == EVENT_TYPE) {
					$message .= $counter." - ".$condition->get_name.": event type condition\n";
				} else {
					$message .= $counter." - ".$condition->get_name.": '". ($condition->is_fulfilled ? 'true' : 'false') ."'\n";
				}
			} continue {
				$counter++;
			}
			
			
			my $check_state = $eventMacro->{automacros_index_to_AI_check_state}{$automacro->get_index};
			$message .= "----  AI check states   ----\n";
			$message .= "Check on AI off: '". ($check_state->{AI::OFF} ? 'yes' : 'no') ."'\n";
			$message .= "Check on AI manual: '". ($check_state->{AI::MANUAL} ? 'yes' : 'no') ."'\n";
			$message .= "Check on AI auto: '". ($check_state->{AI::AUTO} ? 'yes' : 'no') ."'\n";
			
			$message .= "----  End   ----\n";
			
			message $message;
		}
	
	
	### parameter: list
	} elsif ($arg eq 'list') {
		message( "The following macros are available:\n" );

		message( center( T( ' Macros ' ), 25, '-' ) . "\n", 'list' );
		message( $_->get_name . "\n" ) foreach sort { $a->get_name cmp $b->get_name } @{ $eventMacro->{Macro_List}->getItems };

		message( center( T( ' Auto Macros ' ), 25, '-' ) . "\n", 'list' );
		message( $_->get_name . "\n" ) foreach sort { $a->get_name cmp $b->get_name } @{ $eventMacro->{Automacro_List}->getItems };

		message( center( T( ' Perl Subs ' ), 25, '-' ) . "\n", 'list' );
		message( "$_\n" ) foreach sort @perl_name;

		message( center( '', 25, '-' ) . "\n", 'list' );
		
		
	### parameter: status
	} elsif ($arg eq 'status') {
		if (defined $params[0] && $params[0] ne 'macro' && $params[0] ne 'automacro') {
			message "[eventMacro] '".$params[0]."' is not a valid option\n";
			return;
		}
		if (!defined $params[0] || $params[0] eq 'macro') {
			my $macro = $eventMacro->{Macro_Runner};
			if ( $macro ) {
				message( "There's a macro currently running\n", "list" );
				message( sprintf( "Paused: %s\n", $macro->is_paused ? "yes" : "no" ) );
				
				my $macro_tree_message = "Macro tree: '".$macro->get_name."'";
				my $submacro = $macro;
				while (defined $submacro->{subcall}) {
					$submacro = $submacro->{subcall};
					$macro_tree_message .= " --> '".$submacro->get_name."'";
				}
				$macro_tree_message .= ".\n";
				message( $macro_tree_message, "list" );
				
				while () {
					message( center( " Macro ", 25, '-' ) . "\n", 'list' );
					message( sprintf( "Macro name: %s\n", $macro->get_name ), "list" );
					message( sprintf( "averrideAI: %s\n", $macro->overrideAI ), "list" );
					message( sprintf( "interruptible: %s\n", $macro->interruptible ), "list" );
					message( sprintf( "orphan method: %s\n", $macro->orphan ), "list" );
					message( sprintf( "remaining repeats: %s\n", $macro->repeat ), "list" );
					message( sprintf( "macro delay: %s\n", $macro->macro_delay ), "list" );
					
					message( sprintf( "current command: %s\n", $macro->{current_line} ), "list" );
					
					my $time_until_next_command = (($macro->timeout->{time} + $macro->timeout->{timeout}) - time);
					message( sprintf( "time until next command: %s\n", $macro->macro_delay ), "list" ) if ($time_until_next_command > 0);
					
					message "\n";
					
					last if (!defined $macro->{subcall});
					$macro = $macro->{subcall};
				}
			} else {
				message "There's no macro currently running.\n";
			}
		}
		if (!defined $params[0] || $params[0] eq 'automacro') {
			my $status = $eventMacro->get_automacro_checking_status();
			if ($status == CHECKING_AUTOMACROS) {
				message "Automacros are being checked normally.\n";
			} elsif ($status == PAUSED_BY_EXCLUSIVE_MACRO) {
				message "Automacros are not being checked because there's an uninterruptible macro running ('".$eventMacro->{Macro_Runner}->last_subcall_name."').\n";
			} elsif ($status == PAUSE_FORCED_BY_USER) {
				message "Automacros checking is stopped because the user forced it.\n";
			} else {
				message "Automacros checking is active because the user forced it.\n";
			}
		}
		
	### parameter: check
	} elsif ($arg eq 'check') {
		if (!defined $params[0] || (defined $params[0] && $params[0] ne 'force_stop' && $params[0] ne 'force_start' && $params[0] ne 'resume')) {
			message "usage: eventMacro check [force_stop|force_start|resume]\n", "list";
			message 
				"eventMacro check force_stop: forces the stop of automacros checking\n".
				"eventMacro check force_start: forces the start of automacros checking\n".
				"eventMacro check resume: return automacros checking to the normal state\n";
			return;
		}
		my $status = $eventMacro->get_automacro_checking_status();
		debug "[eventMacro] Command 'check' used with parameter '".$params[0]."'.\n", "eventMacro", 2;
		debug "[eventMacro] Previous checking status '".$status."'.\n", "eventMacro", 2;
		if ($params[0] eq 'force_stop') {
			if ($status == CHECKING_AUTOMACROS) {
				message "[eventMacro] Automacros checking forcely stopped.\n";
				$eventMacro->set_automacro_checking_status(PAUSE_FORCED_BY_USER);
			} elsif ($status == PAUSED_BY_EXCLUSIVE_MACRO) {
				message "[eventMacro] Automacros were not being checked because there's an uninterruptible macro running ('".$eventMacro->{Macro_Runner}->last_subcall_name."').".
				        "Now they will be forcely stopped even after macro ends (caution).\n";
				$eventMacro->set_automacro_checking_status(PAUSE_FORCED_BY_USER);
			} elsif ($status == PAUSE_FORCED_BY_USER) {
				message "[eventMacro] Automacros checking is already forcely stopped.\n";
			} else {
				message "[eventMacro] Automacros checking is forcely active, now it will be forcely stopped.\n";
				$eventMacro->set_automacro_checking_status(PAUSE_FORCED_BY_USER);
			}
		} elsif ($params[0] eq 'force_start') {
			if ($status == CHECKING_AUTOMACROS) {
				message "[eventMacro] Automacros are already being checked, now it will be forcely kept this way.\n";
				$eventMacro->set_automacro_checking_status(CHECKING_FORCED_BY_USER);
			} elsif ($status == PAUSED_BY_EXCLUSIVE_MACRO) {
				message "[eventMacro] Automacros were not being checked because there's an uninterruptible macro running ('".$eventMacro->{Macro_Runner}->last_subcall_name."').".
				        "Now automacros checking will be forcely activated (caution).\n";
				$eventMacro->set_automacro_checking_status(CHECKING_FORCED_BY_USER);
			} elsif ($status == PAUSE_FORCED_BY_USER) {
				message "[eventMacro] Automacros checking is forcely stopped, now it will be forcely activated.\n";
				$eventMacro->set_automacro_checking_status(CHECKING_FORCED_BY_USER);
			} else {
				message "[eventMacro] Automacros checking is already forcely active.\n";
			}
		} else {
			if ($status == CHECKING_AUTOMACROS || $status == PAUSED_BY_EXCLUSIVE_MACRO) {
				message "[eventMacro] Automacros checking is not forced by the user to be able to resume.\n";
			} else {
				if (!defined $eventMacro->{Macro_Runner}) {
					message "[eventMacro] Since there's no macro in execution automacros will resume to being normally checked.\n";
					$eventMacro->set_automacro_checking_status(CHECKING_AUTOMACROS);
				} elsif ($eventMacro->{Macro_Runner}->last_subcall_interruptible == 1) {
					message "[eventMacro] Since there's a macro in execution, and it is interruptible, automacros will resume to being normally checked.\n";
					$eventMacro->set_automacro_checking_status(CHECKING_AUTOMACROS);
				} elsif ($eventMacro->{Macro_Runner}->last_subcall_interruptible == 0) {
					message "[eventMacro] Since there's a macro in execution ('".$eventMacro->{Macro_Runner}->last_subcall_name."') , and it is not interruptible, automacros won't resume to being checked until it ends.\n";
					$eventMacro->set_automacro_checking_status(PAUSED_BY_EXCLUSIVE_MACRO);
				}
			}
		}
	
	
	### parameter: stop
	} elsif ($arg eq 'stop') {
		my $macro = $eventMacro->{Macro_Runner};
		if ( $macro ) {
			message "Stopping macro '".$eventMacro->{Macro_Runner}->last_subcall_name."'.\n";
			$eventMacro->clear_queue();
		} else {
			message "There's no macro currently running.\n";
		}
		
		
	### parameter: pause
	} elsif ($arg eq 'pause') {
		my $macro = $eventMacro->{Macro_Runner};
		if ( $macro ) {
			if ($macro->is_paused()) {
				message "Macro '".$eventMacro->{Macro_Runner}->last_subcall_name."' is already paused.\n";
			} else {
				message "Pausing macro '".$eventMacro->{Macro_Runner}->last_subcall_name."'.\n";
				$eventMacro->{Macro_Runner}->pause();
			}
		} else {
			message "There's no macro currently running.\n";
		}
		
		
	### parameter: unpause
	} elsif ($arg eq 'unpause') {
		my $macro = $eventMacro->{Macro_Runner};
		if ( $macro ) {
			if ($macro->is_paused()) {
				message "Unpausing macro '".$eventMacro->{Macro_Runner}->last_subcall_name."'.\n";
				$eventMacro->{Macro_Runner}->unpause();
			} else {
				message "Macro '".$eventMacro->{Macro_Runner}->last_subcall_name."' is not paused.\n";
			}
		} else {
			message "There's no macro currently running.\n";
		}
		
		
	### parameter: var_get
	} elsif ($arg eq 'var_get') {
		if (!defined $params[0]) {
			my $counter = 1;
			message "[eventMacro] Printing values off all variables\n", "menu";
			foreach my $variable_name (keys %{$eventMacro->{Scalar_Variable_List_Hash}}) {
				message $counter."- '".$variable_name."' = '".$eventMacro->{Scalar_Variable_List_Hash}->{$variable_name}."'\n", "menu";
			} continue {
				$counter++;
			}
			return;
		} else {
			my $var = $params[0];
			$var =~ s/^\$//;
			if ($eventMacro->is_scalar_var_defined($var)) {
				my $value = $eventMacro->get_scalar_var($var);
				message "[eventMacro] Variable '".$params[0]."' has value '".$value."'.\n";
			} else {
				message "[eventMacro] Variable '".$params[0]."' has an undefined value.\n";
			}
		}
	
	### parameter: var_set
	} elsif ($arg eq 'var_set') {
		if (!defined $params[0] || !defined $params[1]) {
			message "usage: eventMacro var_set [variable name] [variable value]\n", "list";
			return;
		}
		my $var = $params[0];
		$var =~ s/^\$//;
		my $value = $params[1];
		if ($var =~ /^\./) {
			error "[eventMacro] System variables cannot be set by hand (The ones starting with a dot '.')\n";
			return;
		}
		message "[eventMacro] Setting the value of variable '".$params[0]."' to '".$params[1]."'.\n";
		$eventMacro->set_scalar_var($var, $value);
		
	### parameter: var_array_set
	} elsif ($arg eq 'var_array_set') {
		if (!defined $params[0] || !defined $params[1] || !defined $params[2]) {
			message "usage: eventMacro var_set [variable name] [index] [variable value]\n", "list";
			return;
		}
		my $var = $params[0];
		$var =~ s/^\$//;
		my $index = $params[1];
		my $value = $params[2];
		if ($var =~ /^\./) {
			error "[eventMacro] System variables cannot be set by hand (The ones starting with a dot '.')\n";
			return;
		}
		message "[eventMacro] Setting the value of variable '".$params[0]."[".$params[1]."]' to '".$params[2]."'.\n";
		$eventMacro->set_array_var($var, $index, $value);
		
		
	### parameter: enable
	} elsif ($arg eq 'enable') {
		if (!defined $params[0]) {
			foreach my $automacro (@{$eventMacro->{Automacro_List}->getItems()}) {
				message "[eventMacro] Enabled automacro '".$automacro->get_name."'.\n";
				$eventMacro->enable_automacro($automacro);
			}
			message "[eventMacro] All automacros were enabled.\n";
			return;
		}
		for my $automacro_name (@params) {
			my $automacro = $eventMacro->{Automacro_List}->getByName($automacro_name);
			if (!$automacro) {
				error "[eventMacro] Automacro '".$automacro_name."' not found.\n"
			} else {
				message "[eventMacro] Enabled automacro '".$automacro_name."'.\n";
				$eventMacro->enable_automacro($automacro);
			}
		}
		

	### parameter: disable
	} elsif ($arg eq 'disable') {
		if (!defined $params[0]) {
			foreach my $automacro (@{$eventMacro->{Automacro_List}->getItems()}) {
				message "[eventMacro] Disabled automacro '".$automacro->get_name."'.\n";
				$eventMacro->disable_automacro($automacro);
			}
			message "[eventMacro] All automacros were disabled.\n";
			return;
		}
		for my $automacro_name (@params) {
			my $automacro = $eventMacro->{Automacro_List}->getByName($automacro_name);
			if (!$automacro) {
				error "[eventMacro] Automacro '".$automacro_name."' not found.\n"
			} else {
				message "[eventMacro] Disabled automacro '".$automacro_name."'.\n";
				$eventMacro->disabled_automacro($automacro);
			}
		}
	
	### if nothing triggered until here it's probably a macro name
	} elsif ( !$eventMacro->{Macro_List}->getByName( $arg ) ) {
		error "[eventMacro] Macro $arg not found\n";
	} elsif ( $eventMacro->{Macro_Runner} ) {
		warning "[eventMacro] A macro is already running. Wait until the macro has finished or call 'eventMacro stop'\n";
		return;
	} else {
		my $opt = {};
		GetOptionsFromArray( \@params, $opt, 'repeat|r=i', 'override_ai', 'exclusive', 'macro_delay=f', 'orphan=s' );
		
		# TODO: Determine if this is reasonably efficient for macro sets which define a lot of variables. (A regex is slow.)
		foreach my $variable_name ( keys %{ $eventMacro->{Scalar_Variable_List_Hash} } ) {
			next if $variable_name !~ /^\.param\d+$/o;
			$eventMacro->set_scalar_var( $variable_name, undef, 0 );
		}
		$eventMacro->set_scalar_var( ".param$_", $params[ $_ - 1 ], 0 ) foreach 1 .. @params;
		
		$eventMacro->{Macro_Runner} = new eventMacro::Runner(
			$arg,
			defined $opt->{repeat} ? $opt->{repeat} : 1,
			defined $opt->{exclusive} ? $opt->{exclusive} ? 0 : 1 : undef,
			defined $opt->{override_ai} ? $opt->{override_ai} : undef,
			defined $opt->{orphan} ? $opt->{orphan} : undef,
			undef,
			defined $opt->{macro_delay} ? $opt->{macro_delay} : undef,
			0
		);

		if ( defined $eventMacro->{Macro_Runner} ) {
			$eventMacro->{AI_start_Macros_Running_Hook_Handle} = Plugins::addHook( 'AI_start', sub { $eventMacro->iterate_macro }, undef );
		} else {
			error "[eventMacro] unable to create macro queue.\n";
		}
	}
}

1;