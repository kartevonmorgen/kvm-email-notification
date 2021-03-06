module WelcomeEmail.Server.Services.RecentlyChanged where

import ThisPrelude

import Control.Monad.Except (catchError)
import Data.Array as A
import Data.Generic.Rep (class Generic)
import Data.JSDate (now)
import Data.Set as Set
import Data.Show.Generic (genericShow)
import Data.Time.Duration (Minutes(..), convertDuration)
import Data.Tuple.Nested ((/\))
import Effect.Aff (delay, launchAff_)
import WelcomeEmail.Server.Services.OfdbApi (class OfdbApi, OfdbApiRest(..), defaultRcQuery, getEntriesRecentlyChanged)
import WelcomeEmail.Server.Services.SingletonRepo (class SingletonRepo, SingletonFileRepo(..), load)
import WelcomeEmail.Server.Services.SingletonRepo as SingletonRepo
import WelcomeEmail.Shared.Boundary (EntryChange, EntryChangeA(..))
import WelcomeEmail.Shared.Entry (Entry)
import WelcomeEmail.Shared.Util (logExceptConsole)


data Error
  = OtherError String

derive instance Eq Error
derive instance Generic Error _
instance Show Error where show = genericShow

class RecentlyChanged rc where
  recentlyChanged :: forall m. MonadAff m => rc -> ExceptT Error m (Array EntryChange)


newtype RecentlyChangedFiles rcR = RecentlyChangedFiles { recentlyChangedRepo :: rcR }

instance RecentlyChanged (RecentlyChangedFiles SingletonFileRepo) where
  recentlyChanged (RecentlyChangedFiles { recentlyChangedRepo }) = do
    EntryChangeA eca <- load recentlyChangedRepo # withExceptT (OtherError <<< show)
    pure eca


updateFeed :: forall m ofdbApi rcR.
  MonadAff m => OfdbApi ofdbApi => SingletonRepo rcR EntryChangeA =>
  ofdbApi -> RecentlyChangedFiles rcR -> ExceptT Error m Unit
updateFeed ofdbApi (RecentlyChangedFiles { recentlyChangedRepo }) = do
  entries <- getEntriesRecentlyChanged defaultRcQuery { withRatings = Just true } ofdbApi # withExceptT (OtherError <<< show)
  repoEntries :: Array EntryChange <- (SingletonRepo.load recentlyChangedRepo >>= pure <<< unwrap) `catchError` (\_ -> pure []) # withExceptT (OtherError <<< show)
  now <- liftEffect now
  let dedupEs = dedupEntries entries repoEntries
  let (newRepoEntries :: Array EntryChange) = ((\entry -> { changed: now, entry }) <$> dedupEs) <> repoEntries
  SingletonRepo.save (wrap newRepoEntries) recentlyChangedRepo # withExceptT (OtherError <<< show)
  pure unit

dedupEntries :: Array Entry -> Array EntryChange -> Array Entry
dedupEntries newEntries repoEntries = A.filter notInRepo newEntries
  where
  notInRepo entry = not Set.member (entry.id /\ entry.version) idSet
  idSet = Set.fromFoldable ((\{ entry } -> entry.id /\ entry.version) <$> repoEntries)

-- defaultRecentlyChanged :: forall rc. RecentlyChanged rc => rc
-- defaultRecentlyChanged = defaultRecentlyChangedFiles

defaultRecentlyChangedFiles :: RecentlyChangedFiles SingletonFileRepo
defaultRecentlyChangedFiles = RecentlyChangedFiles { recentlyChangedRepo: SingletonFileRepo "data/recently-changed.json" }

runRecentlyChangedService :: forall m. MonadEffect m => m Unit
runRecentlyChangedService = do
  let
    rcRepo = defaultRecentlyChangedFiles
    ofdbApi = OfdbApiRest { baseUrl: "https://api.ofdb.io/v0" }
    loop = do
      logExceptConsole $ updateFeed ofdbApi rcRepo
      delay $ convertDuration $ Minutes 11.0
      loop
  liftEffect $ launchAff_ loop

newtype Mock = Mock (Either Error (Array EntryChange))

instance RecentlyChanged Mock where
  recentlyChanged (Mock res) = except res


