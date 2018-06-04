# jenkins-pipeline-params
2018/4/27

通过报错发现的 pipeline 参数相关的内容：

Valid parameter types: [booleanParam, choice, credentials, file, text, password, run, string]



InputStep(
  message: String,
  id?: String,
  ok?: String,
  parameters?: ParameterDefinition{
    BooleanParameterDefinition(name: String, defaultValue: boolean, description: String)
    ChoiceParameterDefinition(name: String, choices: String, description: String)
    CredentialsParameterDefinition(name: String, description: String, defaultValue: String, credentialType: String, required: boolean)
    FileParameterDefinition(name: String, description: String)
    GitParameterDefinition(name: String, type: String, defaultValue: String, description: String, branch: String, branchFilter: String, tagFilter: String, sortMode: SortMode[NONE, ASCENDING_SMART, DESCENDING_SMART, ASCENDING, DESCENDING], selectedValue: SelectedValue[NONE, TOP, DEFAULT], useRepository: String, quickFilterEnabled: boolean)
    JiraIssueParameterDefinition(name: String, description: String, jiraIssueFilter: String)
    JiraVersionParameterDefinition(name: String, description: String, jiraProjectKey: String, jiraReleasePattern: String, jiraShowReleased: String, jiraShowArchived: String) | ListSubversionTagsParameterDefinition(name: String, tagsDir: String, credentialsId: String, tagsFilter: String, defaultValue: String, maxTags: String, reverseByDate: boolean, reverseByName: boolean)
    PasswordParameterDefinition(name: String, defaultValue: String, description: String)
    RunParameterDefinition(name: String, projectName: String, description: String, filter: RunParameterFilter[ALL, STABLE, SUCCESSFUL, COMPLETED])
    StringParameterDefinition(name: String, defaultValue: String, description: String)
    TextParameterDefinition(name: String, defaultValue: String, description: String)
  }[],
  submitter?: String,
  submitterParameter?: String
)
