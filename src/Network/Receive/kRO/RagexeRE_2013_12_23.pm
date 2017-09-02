#########################################################################
#  OpenKore - Packet Receiveing
#  This module contains functions for Receiveing packets to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
########################################################################
# Korea (kRO)
# The majority of private servers use eAthena, this is a clone of kRO

package Network::Receive::kRO::RagexeRE_2013_12_23;

use strict;
use base qw(Network::Receive::kRO::RagexeRE_2013_08_07a);

sub new {
   my ($class) = @_;
   my $self = $class->SUPER::new(@_);
   
   my %packets = (
		'09CA' => ['area_spell_multiple3', 'v a*', [qw(len spellInfo)]], # -1
		#'09CB' => ['skill_used_no_damage', 'v2 v a4 a4 C', [qw(skillID lv amount targetID sourceID success)]], # 17
		'09CB' => ['skill_used_no_damage', 'v v x2 a4 a4 C', [qw(skillID amount targetID sourceID success)]],  #16
		'09DB' => ['actor_moved', 'v C a4 a4 v3 V v5 a4 v6 a4 a2 v V C2 a6 C2 v2 a9 Z*', [qw(len object_type ID charID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tick tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize lv font opt4 name)]],
		'09DC' => ['actor_connected', 'v C a4 a4 v3 V v11 a4 a2 v V C2 a3 C2 v2 a9 Z*', [qw(len object_type ID charID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize lv font opt4 name)]],
		'09DD' => ['actor_exists', 'v C a4 a4 v3 V v11 a4 a2 v V C2 a3 C3 v2 a9 Z*', [qw(len object_type ID charID walk_speed opt1 opt2 option type hair_style weapon shield lowhead tophead midhead hair_color clothes_color head_dir costume guildID emblemID manner opt3 stance sex coords xSize ySize act lv font opt4 name)]],
	);

	foreach my $switch (keys %packets) {
      $self->{packet_list}{$switch} = $packets{$switch};
   }
   
   my %handlers = qw(
      actor_connected 09DC
      actor_moved 09DB
      actor_exists 09DD
      actor_display 0086
   );
   
   foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }

   return $self;
}

1;
=pod
// 2013-12-23Ragexe
#elif PACKETVER == 20131223
	parseable_packet(0x0202,5,clif_parse_ChangeDir,2,4);
	parseable_packet(0x022D,19,clif_parse_WantToConnection,2,6,10,14,18);
	parseable_packet(0x023B,26,clif_parse_FriendsListAdd,2);
	parseable_packet(0x0281,-1,clif_parse_ItemListWindowSelected,2,4,8,12);
	parseable_packet(0x035F,6,clif_parse_TickSend,2);
	parseable_packet(0x0360,6,clif_parse_ReqClickBuyingStore,2);
	parseable_packet(0x0361,5,clif_parse_HomMenu,2,4);
	parseable_packet(0x0362,6,clif_parse_DropItem,2,4);
	//parseable_packet(0x0363,8,NULL,0); // CZ_JOIN_BATTLE_FIELD
	parseable_packet(0x0364,8,clif_parse_MoveFromKafra,2,4);
	parseable_packet(0x0365,18,clif_parse_PartyBookingRegisterReq,2,4,6);
	parseable_packet(0x0366,90,clif_parse_UseSkillToPosMoreInfo,2,4,6,8,10);
	parseable_packet(0x0368,6,clif_parse_SolveCharName,2);
	parseable_packet(0x0369,7,clif_parse_ActionRequest,2,6);
	//parseable_packet(0x0436,4,NULL,0); // CZ_GANGSI_RANK
	parseable_packet(0x0437,5,clif_parse_WalkToXY,2);
	parseable_packet(0x0438,10,clif_parse_UseSkillToPos,2,4,6,8);
	parseable_packet(0x07E4,6,clif_parse_TakeItem,2);
	parseable_packet(0x07EC,8,clif_parse_MoveToKafra,2,4);
	parseable_packet(0x0802,26,clif_parse_PartyInvite2,2);
	parseable_packet(0x0811,-1,clif_parse_ReqTradeBuyingStore,2,4,8,12);
	parseable_packet(0x0815,-1,clif_parse_ReqOpenBuyingStore,2,4,8,9,89);
	parseable_packet(0x0817,2,clif_parse_ReqCloseBuyingStore,0);
	parseable_packet(0x0819,-1,clif_parse_SearchStoreInfo,2,4,5,9,13,14,15);
	parseable_packet(0x0835,2,clif_parse_SearchStoreInfoNextPage,0);
	parseable_packet(0x0838,12,clif_parse_SearchStoreInfoListItemClick,2,6,10);
	parseable_packet(0x083C,10,clif_parse_UseSkillToId,2,4,6);
	parseable_packet(0x08A4,36,clif_parse_StoragePassword,2,4,20);
	parseable_packet(0x096A,6,clif_parse_GetCharNameRequest,2);
=cut
