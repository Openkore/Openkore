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

package Network::Send::kRO::RagexeRE_2013_12_23;

use strict;
use base qw(Network::Send::kRO::RagexeRE_2013_08_07a);

sub new {
   my ($class) = @_;
   my $self = $class->SUPER::new(@_);
   
   my %packets = (
      '0202' => ['actor_look_at', 'v C', [qw(head body)]],
      '0811' => ['buy_bulk_buyer', 'a4 a4 a*', [qw(buyerID buyingStoreID itemInfo)]], #Buying store
      '023B' => ['friend_request', 'a*', [qw(username)]],# len 26
      '0361' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
      '022D' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
      '08A4' => ['storage_password'],
   );
   
   $self->{packet_list}{$_} = $packets{$_} for keys %packets;
   
   my %handlers = qw(
      actor_look_at 0202
      buy_bulk_buyer 0811
      friend_request 023B
      homunculus_command 0361
      map_login 022D
      storage_password 08A4
   );
   
   while (my ($k, $v) = each %packets) { $handlers{$v->[0]} = $k}
   
   $self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
   
#   $self->cryptKeys(, , );

   return $self;
}

1;
