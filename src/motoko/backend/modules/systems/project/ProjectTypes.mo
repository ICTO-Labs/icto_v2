import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Time "mo:base/Time";
import ICRC "../../../../shared/types/ICRC";

module ProjectTypes {
  public type ProjectId = Text;

  public type Project = {
    id : ProjectId;
    name : Text;
    description : Text;
    logo : Text;
    owner : Principal.Principal;
    tokenSymbol : Text;
    tokenCanister : ?Principal;
    launchpadCanister : ?Principal.Principal;
    lockCanisters : [Principal.Principal];
    distributionCanisters : [Principal.Principal];
    createdAt : Time.Time;
    updatedAt : Time.Time;
  };

  public type State = { 
    var projects : Trie.Trie<ProjectId, Project>;
  };

  public type StableState = { 
    projects : [(ProjectId, Project)];
  };

  public func emptyState() : State {
    {
      var projects = Trie.empty();
    }
  };
}; 