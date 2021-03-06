"f.groupsum"<-
function(X, INDICES, expand = T)
{
# INDICES DEFINES GROUPS (FOR THE TIME BEING THIS CAN ONLY BE A SINGLE VECTOR)
# X CONTAINS NUMERICAL VALUES
# THE FUNCTION SUMS THE X-VALUES OVER GROUPS DEFINED BY INDICES, THEN
# EXPANDS THE SUM VECTOR TO MATCH THE INDICES VECTOR IN THE ORIGINAL ORDERING
#
# WHEN expand = F THE RESULT IS not EXPANDED BACK INTO THE ORIGINAL SIZE, ONLY
# ONE VALUE IS RETAINED FOR EACH OF THE VALUES OF INDICES. THE CORRESPONDING
# INDICES ARE THEN ALSO RETURNED, IN A DATA FRAME
#
# PROBABLY MORE EFFICIENT THAN JUST USING tapply IN THE CASE OF MANY GROUPS
#
# NOTE: CAN ALSO BE USED TO COMPUTE FREQUENCIES
#
if(length(X) != length(INDICES)) stop("Different lengths of X and INDICES!")	#
#
.l <- length(X)
.order <- order(INDICES, na.last = T)	# SAVE ORIGINAL ORDERING
.x <- X[.order]	#
#
#
.indices <- match(INDICES[.order], unique.default(INDICES[.order])) # ASSIGN UNIQUE INTEGER RANKS, AVOID codes SINCE THIS IS NOT PRESENT IN MOST RECENT R
#
#
## COMPUTE CUMULATIVE SUM IN ORDERED SEQUENCE, THEN COMPUTE DIFFERENCES WHERE NEW GROUPS OCCUR:
.cumsum <- cumsum(.x)
.cumsum <- c(.cumsum, .cumsum[.l])
#
.first <- c(!duplicated(.indices), T)	# FIRST IN EACH GROUP
.ind <- (1:.l)[.first[-1]]	# LAST IN EACH GROUP
#

.step <- c(.cumsum[.ind][1], diff(.cumsum[.ind]))	# COMPUTE INCREASE IN CUMSUM OVER EACH GROUP
#
.sum <- .step[.indices]	# MATCH BACK TO SORTED INDICES
.sum <- .sum[order(.order)]	# SORT BACK TO ORIGINAL ORDERING

#
if(!expand){
		.nondup <- !duplicated(INDICES)
		.ut <- dframe(sumx = .sum[.nondup], INDICES = INDICES[.nondup]) 
			# IN ORIGINAL ORDERING!! BUT ONLY FIRST OF EACH KIND
		return(.ut)
	}
#
return(.sum)
}
