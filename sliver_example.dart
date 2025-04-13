import 'dart:developer';

import 'package:events_discovery/presentation/home/compo/review_eventcard.dart';
import 'package:events_discovery/presentation/home/sections_components/global_events_section.dart';

import '../../../discovery_app.dart';
import '../../dashboard/dashboard/compo/top_organisers_around.dart';
import '../../feed/compo/curated_bucket_home.dart';
import '../../profile/compo/profile_home_header.dart';
import '../../search/compo/recent_viewed_events_section.dart';
import '../../search/screen/invalid_city_compo.dart';
import '../../search/shimmer/home_shimmer.dart';
import '../../welcome/screens/category_select_screen.dart';
import '../compo/end_screen_compo.dart';
import '../compo/home_cache_handling.dart';
import '../compo/home_dates_filter.dart';
import '../compo/home_friends_to_follow.dart';
import '../compo/home_people_tofollow.dart';
import '../compo/home_popular_section.dart';
import '../compo/home_screen_appbar.dart';
import '../compo/home_trending_categories.dart';
import '../compo/interested_bucket_home.dart';
import '../compo/onboarding_popup.dart';
import '../compo/upcoming_events_buckets.dart';
import '../event_compo/featured_events.dart';

class HomeScreen extends StatefulHookConsumerWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(homeProvider).homeScreenInitialMethod();
    
    // Add scroll listener to update filter chips visibility
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider).scrollController?.addListener(_handleScroll);
    });
  }
  
  @override
  void dispose() {
    ref.read(homeProvider).scrollController?.removeListener(_handleScroll);
    super.dispose();
  }
  
  void _handleScroll() {
    final scrollController = ref.read(homeProvider).scrollController;
    if (scrollController == null || !scrollController.hasClients) return;
    
    final offset = scrollController.offset;
    final showFilterChips = ref.read(homeProvider).showFilterChips;
    
    if (offset > 150 && !showFilterChips) {
      ref.read(homeProvider).setShowFilterChips(true);
    } else if (offset <= 150 && showFilterChips) {
      ref.read(homeProvider).setShowFilterChips(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(homeProvider).getArtistList();
          await ref.refresh(bucketEventsFutureProvider.future).then((value) {});
        },
        child: Stack(
          children: [
            CustomScrollView(
              controller: ref.watch(homeProvider).scrollController,
              slivers: [
                const HomeScreenAppBar(),
                // Global Events Section with proper sliver integration
                const GlobalEventsSection(),
                SliverToBoxAdapter(
                  child: ListView.builder(
                    itemCount: 1,
                    shrinkWrap: true,
                    physics: const ScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (BuildContext context, int topIndex) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ref.watch(userProvider).fetchingUserProfile || ref.watch(userProvider).currentAeUser == null ? const Sbe() : const ProfileHomeHeader(),
                          ref.watch(bucketEventsFutureProvider).when(
                                skipLoadingOnRefresh: false,
                                skipLoadingOnReload: true,
                                data: (bucketData) {
                                  final isFeaturedEventsAvailable = (bucketData.data ?? []).isNotEmpty ? ((bucketData.data ?? []).first.title ?? "").toLowerCase().contains('featured') : false;
                                  final bucketEventsList = (bucketData.data ?? []).where((element) => !(element.title ?? "").toLowerCase().contains('featured')).toList();
                                  return !ref.watch(authProvider).isConnectedToNetwork
                                      ? const Center(child: InternetPlaceholder())
                                      : bucketData.data!.isEmpty && bucketData.error == "1"
                                          ? const Center(child: InvalidCityCompo())
                                          : bucketData.data!.length == 1 && bucketData.data![0].title!.contains('around')
                                              ? InvalidCityCompo(bucket: bucketData.data![0])
                                              : Column(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  children: [
                                                    !isFeaturedEventsAvailable
                                                        ? const SizedBox()
                                                        : Padding(
                                                            padding: EdgeInsets.symmetric(horizontal: 10.sp),
                                                            child: HomeArrowHeading(
                                                              title: bucketData.data![0].title!.replaceFirst('in ${ref.watch(locationProvider).selectedCity?.city}', '').replaceFirst("around ${ref.watch(locationProvider).selectedCity?.city}", 'around'),
                                                              onViewMore: () {},
                                                            ),
                                                          ),
                                                    !isFeaturedEventsAvailable ? const SizedBox() : FeaturedEvents(features: bucketData.data![0].events!, titleTag: bucketData.data![0].title!),
                                                    ref.watch(categoryLocationFutureProvider).when(
                                                      data: (bucketData) {
                                                        return bucketData.isEmpty ? const SizedBox() : HomeTrendingCategories(categories: bucketData);
                                                      },
                                                      error: (error, stackTrace) {
                                                        return const SizedBox();
                                                      },
                                                      loading: () {
                                                        return const HomeTrendingShimmer();
                                                      },
                                                    ),
                                                    SizedBox(height: 20.sp),
                                                    const HomeFriendsToFollow(source: 'Tab: Home: ${KStrings.friendsToFollow}'),
                                                    UpcomingEventsBucketHome(tabs: bucketData.tabs),
                                                    const CuratedEventsBucketHome(),
                                                    ref.watch(recentlyViewedFutureProvider).when(data: (eventItem) {
                                                      return eventItem.isEmpty ? Sbh(h: 20.sp) : const Sbe();
                                                    }, error: (error, stackTrace) {
                                                      return const Sbe();
                                                    }, loading: () {
                                                      return const Sbe();
                                                    }),
                                                    const RecentViewedEventsSection(source: "Tab: Home"),
                                                    if (bucketEventsList.length < 4)
                                                      Column(
                                                        children: [
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              return PopularHomeSection(bucket: bucketEventsList[index]);
                                                            },
                                                          ),
                                                          const ArtistsOnTourSection(),
                                                          SizedBox(height: 20.sp),
                                                          HomePeopleToFollow(banner: bucketData.banners!.friendsBanner ?? ""),
                                                        ],
                                                      )
                                                    // if more than 7
                                                    else if (bucketEventsList.length > 7)
                                                      Column(
                                                        children: [
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.take(2).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              return PopularHomeSection(bucket: bucketEventsList[index]);
                                                            },
                                                          ),
                                                          const ArtistsOnTourSection(),
                                                          SizedBox(height: 20.sp),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(4).toList().take(2).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(2).toList().take(2).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                          const HomeDatesFilter(),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(4).toList().take(2).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(4).toList().take(2).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                          HomePeopleToFollow(banner: bucketData.banners!.friendsBanner ?? ""),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(6).toList().take(2).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(6).toList().take(2).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                          TopOrganizersAroundSection(source: "Tab: Home", bottomPadding: 12.sp),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(8).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(8).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                        ],
                                                      )
                                                    // between 4-7 buckets
                                                    else
                                                      Column(
                                                        children: [
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.take(1).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              return PopularHomeSection(
                                                                bucket: bucketEventsList[index],
                                                              );
                                                            },
                                                          ),
                                                          const ArtistsOnTourSection(),
                                                          SizedBox(height: 20.sp),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(1).toList().take(1).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(1).toList().take(1).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                          const HomeDatesFilter(),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(2).toList().take(1).length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(2).toList().take(1).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                          HomePeopleToFollow(banner: bucketData.banners!.friendsBanner ?? ""),
                                                          ListView.builder(
                                                            padding: EdgeInsets.zero,
                                                            itemCount: bucketEventsList.skip(3).toList().length,
                                                            shrinkWrap: true,
                                                            physics: const ScrollPhysics(),
                                                            itemBuilder: (BuildContext context, int index) {
                                                              final bucketEvents = bucketEventsList.skip(3).toList()[index];
                                                              return PopularHomeSection(bucket: bucketEvents);
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    const InterestedBucketHome(),
                                                    const EndScreenCompo(),
                                                  ],
                                                );
                                },
                                error: (error, stackTrace) {
                                  log("Error on ${error.toString()}");
                                  return ErrorPlaceholder(
                                    onCtaCallback: () async {
                                      ref.read(homeProvider).getArtistList();
                                      await ref.refresh(bucketEventsFutureProvider.future).then((value) {});
                                    },
                                  );
                                },
                                loading: () {
                                  return const HomeCacheHandling();
                                },
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // Onboarding popup
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              bottom: ref.watch(showcaseProvider).isShowCaseVisible ? 0 : -48.sp,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {},
                child: const OnboardingPopup(),
              ),
            ),
            // Feedback popup
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              bottom: ref.watch(homeProvider).isShowFeedbackPopup ? 0 : -80.sp,
              left: 0,
              right: 0,
              child: ReviewEventCard(),
            ),
          ],
        ),
      ),
    );
  }
}
