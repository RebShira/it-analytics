from django import forms

class SelectAmpOrDept(forms.Form):

    selection = forms.ChoiceField(label='Select AMP or Dept: ')

    def populate(self, json_object):
        self.selection.choices = json_object
