#########################################################################
#  OpenKore - Packet sending
#  This module contains functions for sending packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
########################################################################

package Network::Send::kRO::RagexeRE_2017_04_25d;

use strict;
use base qw(Network::Send::kRO::RagexeRE_2017_04_19);

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0369' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'096A' => ['actor_info_request', 'a4', [qw(ID)]],
		'0927' => ['actor_look_at', 'v C', [qw(head body)]],
		'0887' => ['actor_name_request', 'a4', [qw(ID)]],
		'0811' => ['buy_bulk_buyer', 'a4 a4 a*', [qw(buyerID buyingStoreID itemInfo)]], #Buying store
		'0817' => ['buy_bulk_closeShop'],			
		'0815' => ['buy_bulk_openShop', 'a4 c a*', [qw(limitZeny result itemInfo)]], #Selling store
		'0360' => ['buy_bulk_request', 'a4', [qw(ID)]], #6
		'0437' => ['character_move', 'a3', [qw(coordString)]],
		'0958' => ['friend_request', 'a*', [qw(username)]],# len 26
		'089C' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'0940' => ['item_drop', 'a2 v', [qw(ID amount)]],
		'0866' => ['item_list_res', 'v V2 a*', [qw(len type action itemInfo)]],
		'08A4' => ['item_take', 'a4', [qw(ID)]],
		'08A2' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'0802' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],
		'083C' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0438' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'0963' => ['storage_item_add', 'a2 V', [qw(ID amount)]],
		'0899' => ['storage_item_remove', 'a2 V', [qw(ID amount)]],
		'0281' => ['storage_password'],
		'035F' => ['sync', 'V', [qw(time)]],		
	);
	
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	my %handlers = qw(
		actor_action 0369
		actor_info_request 096A
		actor_look_at 0927
		actor_name_request 0887
		buy_bulk_buyer 0811
		buy_bulk_closeShop 0817
		buy_bulk_openShop 0815
		buy_bulk_request 0360
		character_move 0437
		friend_request 0958
		homunculus_command 089C
		item_drop 0940
		item_list_res 0866
		item_take 08A4
		map_login 08A2
		party_join_request_by_name 0802
		skill_use 083C
		skill_use_location 0438
		storage_item_add 0963
		storage_item_remove 0899
		storage_password 0281
		sync 035F
	);
	
	while (my ($k, $v) = each %packets) { $handlers{$v->[0]} = $k}
	
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
#	elif PACKETVER == 20170426 // 2017-04-26dRagexeRE
#	packet_keys(0x167642A7,0x1DEC3D26,0x6D046D4C);
#	use $key1 $key3 $key2
#	$self->cryptKeys(0x167642A7,0x6D046D4C,0x1DEC3D26);


	return $self;
}

1;
